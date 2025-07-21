from flask import Flask, request, jsonify, send_file
import pyautogui
import time
import os

# Disable PyAutoGUI fail-safe for Docker container usage
# The fail-safe is designed to prevent runaway automation on desktops
# but is counterproductive in a controlled container environment
pyautogui.FAILSAFE = False

app = Flask(__name__)

# Configuration for desktop snapshots
SNAPSHOT_PATH = os.environ.get('SNAPSHOT_PATH', '/tmp/desktop_snapshot.png')

# Configuration for key press duration
DEFAULT_KEY_DURATION_MS = int(os.environ.get('DEFAULT_KEY_DURATION_MS', '100'))

@app.route('/send-key', methods=['POST'])
def send_key():
    try:
        data = request.json
        key = data.get('key')
        duration_ms = data.get('duration_ms', DEFAULT_KEY_DURATION_MS)
        
        if not key:
            return jsonify({'error': 'Key is required'}), 400
        
        if duration_ms <= 0:
            return jsonify({'error': 'Duration must be positive'}), 400
        
        # For very short durations, use the default press method
        if duration_ms < 50:
            pyautogui.press(key)
        else:
            # Use keyDown/keyUp for longer durations
            pyautogui.keyDown(key)
            time.sleep(duration_ms / 1000.0)
            pyautogui.keyUp(key)
        
        return jsonify({
            'status': 'success', 
            'key': key, 
            'duration_ms': duration_ms
        })
    except Exception as e:
        return jsonify({'error': f'Failed to send key: {str(e)}'}), 500

@app.route('/send-key-duration', methods=['POST'])
def send_key_duration():
    """Endpoint specifically for key presses with custom durations"""
    try:
        data = request.json
        key = data.get('key')
        duration_ms = data.get('duration_ms')
        
        if not key:
            return jsonify({'error': 'Key is required'}), 400
        
        if duration_ms is None:
            return jsonify({'error': 'duration_ms is required'}), 400
        
        if duration_ms <= 0:
            return jsonify({'error': 'Duration must be positive'}), 400
        
        # Always use keyDown/keyUp for explicit duration control
        pyautogui.keyDown(key)
        time.sleep(duration_ms / 1000.0)
        pyautogui.keyUp(key)
        
        return jsonify({
            'status': 'success', 
            'key': key, 
            'duration_ms': duration_ms,
            'method': 'keyDown/keyUp'
        })
    except Exception as e:
        return jsonify({'error': f'Failed to send key with duration: {str(e)}'}), 500

@app.route('/move-mouse', methods=['POST'])
def move_mouse():
    try:
        data = request.json
        x = data.get('x')
        y = data.get('y')
        if x is None or y is None:
            return jsonify({'error': 'x and y are required'}), 400
        pyautogui.moveTo(x, y)
        return jsonify({'status': 'success', 'x': x, 'y': y})
    except Exception as e:
        return jsonify({'error': f'Failed to move mouse: {str(e)}'}), 500

@app.route('/click-mouse', methods=['POST'])
def click_mouse():
    """Mouse click with support for different buttons and click types"""
    try:
        data = request.json
        x = data.get('x')
        y = data.get('y')
        button = data.get('button', 'left')  # left, right, middle
        clicks = data.get('clicks', 1)  # number of clicks
        interval = data.get('interval', 0.0)  # interval between clicks
        
        # Validate coordinates
        if x is None or y is None:
            return jsonify({'error': 'x and y coordinates are required'}), 400
        
        # Validate button
        valid_buttons = ['left', 'right', 'middle']
        if button not in valid_buttons:
            return jsonify({'error': f'Button must be one of: {valid_buttons}'}), 400
        
        # Validate clicks
        if clicks < 1 or clicks > 10:
            return jsonify({'error': 'Clicks must be between 1 and 10'}), 400
        
        # Validate interval
        if interval < 0:
            return jsonify({'error': 'Interval must be non-negative'}), 400
        
        # Perform the click
        pyautogui.click(x, y, clicks=clicks, interval=interval, button=button)
        
        return jsonify({
            'status': 'success',
            'x': x,
            'y': y,
            'button': button,
            'clicks': clicks,
            'interval': interval
        })
    except Exception as e:
        return jsonify({'error': f'Failed to click mouse: {str(e)}'}), 500

@app.route('/drag-mouse', methods=['POST'])
def drag_mouse():
    """Mouse drag operation from start to end coordinates"""
    try:
        data = request.json
        start_x = data.get('start_x')
        start_y = data.get('start_y')
        end_x = data.get('end_x')
        end_y = data.get('end_y')
        duration = data.get('duration', 1.0)  # duration in seconds
        button = data.get('button', 'left')  # button to hold during drag
        
        # Validate coordinates
        required_coords = [start_x, start_y, end_x, end_y]
        if any(coord is None for coord in required_coords):
            return jsonify({'error': 'start_x, start_y, end_x, and end_y are required'}), 400
        
        # Validate button
        valid_buttons = ['left', 'right', 'middle']
        if button not in valid_buttons:
            return jsonify({'error': f'Button must be one of: {valid_buttons}'}), 400
        
        # Validate duration
        if duration <= 0 or duration > 10:
            return jsonify({'error': 'Duration must be between 0 and 10 seconds'}), 400
        
        # Perform the drag operation
        pyautogui.drag(end_x - start_x, end_y - start_y, duration=duration, button=button)
        
        return jsonify({
            'status': 'success',
            'start_x': start_x,
            'start_y': start_y,
            'end_x': end_x,
            'end_y': end_y,
            'duration': duration,
            'button': button
        })
    except Exception as e:
        return jsonify({'error': f'Failed to drag mouse: {str(e)}'}), 500

@app.route('/desktop-snapshot', methods=['GET'])
def get_desktop_snapshot():
    """Get the latest desktop screenshot with metadata"""
    if not os.path.exists(SNAPSHOT_PATH):
        return jsonify({'error': 'No snapshot available - snapshot service may not be running'}), 404
    
    try:
        file_stat = os.stat(SNAPSHOT_PATH)
        current_time = time.time()
        age_seconds = current_time - file_stat.st_mtime
        interval_ms = int(os.environ.get('SNAPSHOT_INTERVAL_MS', '500'))
        
        # Create response with metadata in headers
        response = send_file(
            SNAPSHOT_PATH, 
            mimetype='image/png',
            as_attachment=False,
            download_name='desktop_snapshot.png'
        )
        
        # Add metadata headers
        response.headers['X-Snapshot-Size'] = str(file_stat.st_size)
        response.headers['X-Snapshot-Created'] = str(file_stat.st_mtime)
        response.headers['X-Snapshot-Age-Seconds'] = str(round(age_seconds, 2))
        response.headers['X-Snapshot-Interval-Ms'] = str(interval_ms)
        response.headers['X-Snapshot-Is-Fresh'] = str(age_seconds < (interval_ms / 1000 * 2)).lower()
        response.headers['X-Snapshot-Created-Time'] = time.ctime(file_stat.st_mtime)
        
        return response
        
    except Exception as e:
        return jsonify({'error': f'Failed to serve snapshot: {str(e)}'}), 500

@app.route('/snapshot-info', methods=['GET'])
def get_snapshot_info():
    """Health check endpoint - validates snapshot service is actively generating fresh images"""
    if not os.path.exists(SNAPSHOT_PATH):
        return jsonify({
            'service_healthy': False,
            'snapshot_available': False,
            'message': 'No snapshot available - snapshot service may not be running'
        }), 503
    
    try:
        interval_ms = int(os.environ.get('SNAPSHOT_INTERVAL_MS', '500'))
        wait_time = (interval_ms / 1000) + 0.1  # Wait slightly longer than interval
        
        # Get initial file modification time
        initial_stat = os.stat(SNAPSHOT_PATH)
        initial_mtime = initial_stat.st_mtime
        current_time = time.time()
        initial_age = current_time - initial_mtime
        
        # If file is already very fresh, wait for next update
        if initial_age < (interval_ms / 1000):
            print(f"Waiting {wait_time}s for next snapshot update...")
            time.sleep(wait_time)
        
        # Check if file was updated
        try:
            updated_stat = os.stat(SNAPSHOT_PATH)
            updated_mtime = updated_stat.st_mtime
            file_was_updated = updated_mtime > initial_mtime
        except:
            updated_stat = initial_stat
            updated_mtime = initial_mtime
            file_was_updated = False
        
        # Calculate final metrics
        final_age = time.time() - updated_mtime
        is_fresh = final_age < (interval_ms / 1000 * 3)  # Allow 3x interval tolerance
        service_healthy = file_was_updated or is_fresh
        
        return jsonify({
            'service_healthy': service_healthy,
            'snapshot_available': True,
            'file_size_bytes': updated_stat.st_size,
            'age_seconds': round(final_age, 2),
            'configured_interval_ms': interval_ms,
            'file_was_updated_during_check': file_was_updated,
            'is_fresh': is_fresh,
            'snapshot_path': SNAPSHOT_PATH,
            'check_details': {
                'initial_age_seconds': round(initial_age, 2),
                'waited_seconds': wait_time if initial_age < (interval_ms / 1000) else 0,
                'final_age_seconds': round(final_age, 2)
            }
        }), 200 if service_healthy else 503
        
    except Exception as e:
        return jsonify({
            'service_healthy': False,
            'error': f'Failed to check snapshot service: {str(e)}'
        }), 500

if __name__ == '__main__':
    # Start Flask app - snapshot service runs separately
    print("Starting Flask API server...")
    print(f"Configured snapshot path: {SNAPSHOT_PATH}")
    print(f"Default key duration: {DEFAULT_KEY_DURATION_MS}ms")
    app.run(host='0.0.0.0', port=5000)
