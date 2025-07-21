import requests
import time

BASE_URL = "http://localhost:5000"

def test_send_key():
    print("Testing /send-key endpoint with a short key press...")
    response = requests.post(f"{BASE_URL}/send-key", json={"key": "w"})
    if response.status_code == 200:
        print("✓ Short key press test passed:", response.json())
    else:
        print("✗ Short key press test failed:", response.text)

    print("Testing /send-key endpoint with a longer key press (shift-w)...")
    response = requests.post(f"{BASE_URL}/send-key", json={"key": "shift-w"})
    if response.status_code == 200:
        print("✓ Longer key press test passed:", response.json())
    else:
        print("✗ Longer key press test failed:", response.text)

    print("Testing /send-key endpoint with custom duration (500ms)...")
    response = requests.post(f"{BASE_URL}/send-key", json={"key": "space", "duration_ms": 500})
    if response.status_code == 200:
        print("✓ Custom duration key press test passed:", response.json())
    else:
        print("✗ Custom duration key press test failed:", response.text)

def test_send_key_duration():
    print("\nTesting /send-key-duration endpoint...")
    
    # Test short duration
    print("Testing short duration (50ms)...")
    response = requests.post(f"{BASE_URL}/send-key-duration", json={"key": "a", "duration_ms": 50})
    if response.status_code == 200:
        print("✓ Short duration test passed:", response.json())
    else:
        print("✗ Short duration test failed:", response.text)
    
    # Test medium duration
    print("Testing medium duration (200ms)...")
    response = requests.post(f"{BASE_URL}/send-key-duration", json={"key": "s", "duration_ms": 200})
    if response.status_code == 200:
        print("✓ Medium duration test passed:", response.json())
    else:
        print("✗ Medium duration test failed:", response.text)
    
    # Test long duration
    print("Testing long duration (1000ms)...")
    response = requests.post(f"{BASE_URL}/send-key-duration", json={"key": "d", "duration_ms": 1000})
    if response.status_code == 200:
        print("✓ Long duration test passed:", response.json())
    else:
        print("✗ Long duration test failed:", response.text)
    
    # Test error cases
    print("Testing missing duration parameter...")
    response = requests.post(f"{BASE_URL}/send-key-duration", json={"key": "f"})
    if response.status_code == 400:
        print("✓ Missing duration error test passed:", response.json())
    else:
        print("✗ Missing duration error test failed:", response.text)
    
    print("Testing invalid duration (negative)...")
    response = requests.post(f"{BASE_URL}/send-key-duration", json={"key": "g", "duration_ms": -100})
    if response.status_code == 400:
        print("✓ Invalid duration error test passed:", response.json())
    else:
        print("✗ Invalid duration error test failed:", response.text)

def test_move_mouse():
    print("Testing /move-mouse endpoint...")
    response = requests.post(f"{BASE_URL}/move-mouse", json={"x": 100, "y": 200})
    if response.status_code == 200:
        print("✓ Mouse move test passed:", response.json())
    else:
        print("✗ Mouse move test failed:", response.text)

def test_click_mouse():
    print("\nTesting /click-mouse endpoint...")
    
    # Test basic left click
    print("Testing basic left click...")
    response = requests.post(f"{BASE_URL}/click-mouse", json={"x": 150, "y": 250})
    if response.status_code == 200:
        print("✓ Basic left click test passed:", response.json())
    else:
        print("✗ Basic left click test failed:", response.text)
    
    # Test right click
    print("Testing right click...")
    response = requests.post(f"{BASE_URL}/click-mouse", json={
        "x": 200, "y": 300, "button": "right"
    })
    if response.status_code == 200:
        print("✓ Right click test passed:", response.json())
    else:
        print("✗ Right click test failed:", response.text)
    
    # Test double click
    print("Testing double click...")
    response = requests.post(f"{BASE_URL}/click-mouse", json={
        "x": 250, "y": 350, "clicks": 2, "interval": 0.1
    })
    if response.status_code == 200:
        print("✓ Double click test passed:", response.json())
    else:
        print("✗ Double click test failed:", response.text)
    
    # Test middle button click
    print("Testing middle button click...")
    response = requests.post(f"{BASE_URL}/click-mouse", json={
        "x": 300, "y": 400, "button": "middle"
    })
    if response.status_code == 200:
        print("✓ Middle button click test passed:", response.json())
    else:
        print("✗ Middle button click test failed:", response.text)
    
    # Test error cases
    print("Testing missing coordinates...")
    response = requests.post(f"{BASE_URL}/click-mouse", json={"x": 100})
    if response.status_code == 400:
        print("✓ Missing coordinates error test passed:", response.json())
    else:
        print("✗ Missing coordinates error test failed:", response.text)
    
    print("Testing invalid button...")
    response = requests.post(f"{BASE_URL}/click-mouse", json={
        "x": 100, "y": 200, "button": "invalid"
    })
    if response.status_code == 400:
        print("✓ Invalid button error test passed:", response.json())
    else:
        print("✗ Invalid button error test failed:", response.text)

def test_drag_mouse():
    print("\nTesting /drag-mouse endpoint...")
    
    # Test basic drag
    print("Testing basic drag operation...")
    response = requests.post(f"{BASE_URL}/drag-mouse", json={
        "start_x": 100, "start_y": 100,
        "end_x": 200, "end_y": 200,
        "duration": 0.5
    })
    if response.status_code == 200:
        print("✓ Basic drag test passed:", response.json())
    else:
        print("✗ Basic drag test failed:", response.text)
    
    # Test right button drag
    print("Testing right button drag...")
    response = requests.post(f"{BASE_URL}/drag-mouse", json={
        "start_x": 150, "start_y": 150,
        "end_x": 250, "end_y": 250,
        "duration": 1.0,
        "button": "right"
    })
    if response.status_code == 200:
        print("✓ Right button drag test passed:", response.json())
    else:
        print("✗ Right button drag test failed:", response.text)
    
    # Test longer duration drag
    print("Testing longer duration drag...")
    response = requests.post(f"{BASE_URL}/drag-mouse", json={
        "start_x": 200, "start_y": 200,
        "end_x": 300, "end_y": 100,
        "duration": 2.0
    })
    if response.status_code == 200:
        print("✓ Long duration drag test passed:", response.json())
    else:
        print("✗ Long duration drag test failed:", response.text)
    
    # Test error cases
    print("Testing missing coordinates...")
    response = requests.post(f"{BASE_URL}/drag-mouse", json={
        "start_x": 100, "start_y": 100, "end_x": 200
    })
    if response.status_code == 400:
        print("✓ Missing coordinates error test passed:", response.json())
    else:
        print("✗ Missing coordinates error test failed:", response.text)
    
    print("Testing invalid duration...")
    response = requests.post(f"{BASE_URL}/drag-mouse", json={
        "start_x": 100, "start_y": 100,
        "end_x": 200, "end_y": 200,
        "duration": -1
    })
    if response.status_code == 400:
        print("✓ Invalid duration error test passed:", response.json())
    else:
        print("✗ Invalid duration error test failed:", response.text)
    
    print("Testing invalid button...")
    response = requests.post(f"{BASE_URL}/drag-mouse", json={
        "start_x": 100, "start_y": 100,
        "end_x": 200, "end_y": 200,
        "button": "invalid"
    })
    if response.status_code == 400:
        print("✓ Invalid button error test passed:", response.json())
    else:
        print("✗ Invalid button error test failed:", response.text)

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
            if response.status_code in [200, 503]:  # Both are valid responses
                info = response.json()
                service_healthy = info.get('service_healthy', False)
                snapshot_available = info.get('snapshot_available', False)
                print(f"✓ Instance {instance} (port {port}): Service healthy={service_healthy}, Snapshot available={snapshot_available}")
            else:
                print(f"✗ Instance {instance} (port {port}): Failed with status {response.status_code}")
        except requests.exceptions.RequestException:
            print(f"- Instance {instance} (port {port}): Not running")

if __name__ == "__main__":
    print("🧪 Testing WoW Docker Player API\n")
    
    test_send_key()
    test_send_key_duration()
    test_move_mouse()
    test_click_mouse()
    test_drag_mouse()
    test_desktop_snapshot()
    test_snapshot_service_health()
    test_multiple_instances()
    
    print("\n✅ Test completed!")
    print("📸 If desktop snapshot test passed, check 'test_snapshot.png' file")
