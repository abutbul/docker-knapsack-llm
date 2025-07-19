# Docker LXDE Framebuffer with Wine and Automation API

This project sets up a Docker container with a minimal LXDE environment, Wine, and an API to control keyboard and mouse inputs using `pyautogui`.

## Prerequisites

- Docker installed on your system.

## Build the Docker Image

Run the following command to build the Docker image:

```bash
docker build -t lxde-wine-api .
```

## Run the Docker Container

Start the container with the following command:

```bash
docker run -d --name lxde-wine-container -p 5000:5000 lxde-wine-api
```

- The API will be accessible at `http://localhost:5000`.

## API Endpoints

### 1. Send a Key Press

**Endpoint**: `/send-key`  
**Method**: `POST`  
**Payload**:
```json
{
  "key": "w"
}
```

**Description**: Sends a key press (e.g., `w`, `space`, `1`).

---

### 2. Move the Mouse

**Endpoint**: `/move-mouse`  
**Method**: `POST`  
**Payload**:
```json
{
  "x": 100,
  "y": 200
}
```

**Description**: Moves the mouse to the specified coordinates.

---

## Testing the Setup

Run the provided testing script to verify the container is working as expected:

```bash
python3 test_api.py
```

## Stopping the Container

To stop and remove the container:

```bash
docker stop lxde-wine-container
docker rm lxde-wine-container
```

## Troubleshooting

### 1. X Server Already Running
If you see an error like:
```
A VNC/X11 server is already running as :99 on machine <container_id>
```
This means a stale `.X99-lock` file exists. The Dockerfile has been updated to automatically remove this file before starting the X server.

### 2. Missing `.Xauthority` File
If you see an error like:
```
FileNotFoundError: [Errno 2] No such file or directory: '/root/.Xauthority'
```
The Dockerfile now ensures the `.Xauthority` file is created and configured for the X server.

Rebuild the Docker image and restart the container to apply these fixes:
```bash
docker build -t lxde-wine-api .
docker run -d --name lxde-wine-container -p 5000:5000 -p 5900:5900 lxde-wine-api
```