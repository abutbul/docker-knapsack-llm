import socket

def test_vnc_connection(host="localhost", port=5900):
    print(f"Testing VNC connection to {host}:{port}...")
    try:
        with socket.create_connection((host, port), timeout=5) as sock:
            # Receive the initial data from the VNC server (version string)
            response = sock.recv(1024).decode("utf-8", errors="ignore")
            print(f"Received: {response.strip()}")
            if "RFB" in response:
                print("VNC server is running and accessible.")
                return True
            else:
                print("Connected but did not receive expected VNC protocol string.")
                return False
    except (socket.timeout, ConnectionRefusedError) as e:
        print(f"Failed to connect to VNC server: {e}")
        return False

if __name__ == "__main__":
    if test_vnc_connection():
        print("VNC test passed.")
    else:
        print("VNC test failed. Ensure the container is running and the VNC server is configured correctly.")
