from flask import Flask, request, jsonify
import pyautogui

app = Flask(__name__)

@app.route('/send-key', methods=['POST'])
def send_key():
    data = request.json
    key = data.get('key')
    if not key:
        return jsonify({'error': 'Key is required'}), 400
    pyautogui.press(key)
    return jsonify({'status': 'success', 'key': key})

@app.route('/move-mouse', methods=['POST'])
def move_mouse():
    data = request.json
    x = data.get('x')
    y = data.get('y')
    if x is None or y is None:
        return jsonify({'error': 'x and y are required'}), 400
    pyautogui.moveTo(x, y)
    return jsonify({'status': 'success', 'x': x, 'y': y})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
