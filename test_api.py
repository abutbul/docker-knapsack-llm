import requests
import time

BASE_URL = "http://localhost:5000"

def test_send_key():
    print("Testing /send-key endpoint...")
    response = requests.post(f"{BASE_URL}/send-key", json={"key": "w"})
    if response.status_code == 200:
        print("✓ Key press test passed:", response.json())
    else:
        print("✗ Key press test failed:", response.text)

def test_move_mouse():
    print("Testing /move-mouse endpoint...")
    response = requests.post(f"{BASE_URL}/move-mouse", json={"x": 100, "y": 200})
    if response.status_code == 200:
        print("✓ Mouse move test passed:", response.json())
    else:
        print("✗ Mouse move test failed:", response.text)

def test_desktop_snapshot():
    """Test desktop snapshot endpoint with metadata"""
    print("\n=== Testing Desktop Snapshot ===")
    
    try:
        print("Testing snapshot download with metadata...")
        response = requests.get(f"{BASE_URL}/desktop-snapshot", timeout=10)
        print(f"Snapshot download status: {response.status_code}")
        
        if response.status_code == 200:
            # Save the snapshot to a file for verification
            with open("test_snapshot.png", "wb") as f:
                f.write(response.content)
            
            print(f"✓ Snapshot saved as test_snapshot.png ({len(response.content)} bytes)")
            print(f"Content type: {response.headers.get('Content-Type')}")
            
            # Display metadata from headers
            print("\n📊 Snapshot Metadata:")
            print(f"  Size: {response.headers.get('X-Snapshot-Size')} bytes")
            print(f"  Age: {response.headers.get('X-Snapshot-Age-Seconds')} seconds")
            print(f"  Created: {response.headers.get('X-Snapshot-Created-Time')}")
            print(f"  Interval: {response.headers.get('X-Snapshot-Interval-Ms')}ms")
            print(f"  Fresh: {response.headers.get('X-Snapshot-Is-Fresh')}")
            
            return True
        else:
            print(f"✗ Failed to get snapshot: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"✗ Failed to download snapshot: {e}")
        return False

def test_snapshot_service_health():
    """Test snapshot service health check endpoint"""
    print("\n=== Testing Snapshot Service Health ===")
    
    try:
        print("Testing service health check (this may take a moment)...")
        response = requests.get(f"{BASE_URL}/snapshot-info", timeout=15)
        print(f"Health check status: {response.status_code}")
        
        if response.status_code in [200, 503]:  # Both are valid responses
            info = response.json()
            print(f"Service healthy: {info.get('service_healthy')}")
            print(f"Snapshot available: {info.get('snapshot_available')}")
            print(f"File was updated during check: {info.get('file_was_updated_during_check')}")
            print(f"Age: {info.get('age_seconds')} seconds")
            print(f"Is fresh: {info.get('is_fresh')}")
            print(f"Configured interval: {info.get('configured_interval_ms')}ms")
            
            if 'check_details' in info:
                details = info['check_details']
                print("\n🔍 Check Details:")
                print(f"  Initial age: {details.get('initial_age_seconds')}s")
                print(f"  Waited: {details.get('waited_seconds')}s")
                print(f"  Final age: {details.get('final_age_seconds')}s")
            
            return info.get('service_healthy', False)
        else:
            print(f"✗ Unexpected response: {response.text}")
            return False
    
    except requests.exceptions.RequestException as e:
        print(f"✗ Failed to check service health: {e}")
        return False

def test_multiple_instances():
    """Test API calls to multiple instances if available"""
    print("\nTesting multiple instance APIs...")
    
    for instance in range(1, 4):  # Test instances 1-3
        port = 5000 + (instance - 1)
        url = f"http://localhost:{port}"
        
        try:
            response = requests.get(f"{url}/snapshot-info", timeout=2)
            if response.status_code == 200:
                info = response.json()
                print(f"✓ Instance {instance} (port {port}): Service running={info.get('service_running')}")
            else:
                print(f"✗ Instance {instance} (port {port}): Failed")
        except requests.exceptions.RequestException:
            print(f"- Instance {instance} (port {port}): Not running")

if __name__ == "__main__":
    print("🧪 Testing WoW Docker Player API\n")
    
    test_send_key()
    test_move_mouse()
    test_desktop_snapshot()
    test_snapshot_service_health()
    test_multiple_instances()
    
    print("\n✅ Test completed!")
    print("📸 If desktop snapshot test passed, check 'test_snapshot.png' file")
