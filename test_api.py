import requests

BASE_URL = "http://localhost:5000"

def test_send_key():
    print("Testing /send-key endpoint...")
    response = requests.post(f"{BASE_URL}/send-key", json={"key": "w"})
    if response.status_code == 200:
        print("Key press test passed:", response.json())
    else:
        print("Key press test failed:", response.text)

def test_move_mouse():
    print("Testing /move-mouse endpoint...")
    response = requests.post(f"{BASE_URL}/move-mouse", json={"x": 100, "y": 200})
    if response.status_code == 200:
        print("Mouse move test passed:", response.json())
    else:
        print("Mouse move test failed:", response.text)

if __name__ == "__main__":
    test_send_key()
    test_move_mouse()
