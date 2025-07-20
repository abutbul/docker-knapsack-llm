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

@app.route('/send-key', methods=['POST'])
def send_key():
    try:
        data = request.json
        key = data.get('key')
        if not key:
            return jsonify({'error': 'Key is required'}), 400
        pyautogui.press(key)
        return jsonify({'status': 'success', 'key': key})
    except Exception as e:
        return jsonify({'error': f'Failed to send key: {str(e)}'}), 500

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
    app.run(host='0.0.0.0', port=5000)
