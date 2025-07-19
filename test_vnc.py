import socket

def test_vnc_connection(host="localhost", port=5900):
    print(f"Testing VNC connection to {host}:{port}...")
    try:
        with socket.create_connection((host, port), timeout=5) as sock:
            print("VNC server is running and accessible.")
            return True
    except (socket.timeout, ConnectionRefusedError) as e:
        print(f"Failed to connect to VNC server: {e}")
        return False

if __name__ == "__main__":
    if test_vnc_connection():
        print("VNC test passed.")
    else:
        print("VNC test failed. Ensure the container is running and the VNC server is configured correctly.")
