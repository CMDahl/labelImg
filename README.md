# LabelImg — Docker Setup for Collaborators

LabelImg is a graphical image annotation tool. This repository runs it inside a Docker container, accessible from your web browser — no local Python or GUI installation required.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1 — Clone the Repository](#step-1--clone-the-repository)
- [Step 2 — Build the Docker Image](#step-2--build-the-docker-image)
- [Step 3 — Run the Container](#step-3--run-the-container)
- [Step 4 — Open LabelImg in Your Browser](#step-4--open-labelimg-in-your-browser)
- [Step 5 — Annotate Images](#step-5--annotate-images)
- [Annotation Format](#annotation-format)
- [Predefined Classes](#predefined-classes)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Stopping and Restarting](#stopping-and-restarting)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

You only need **Docker Desktop** installed on your machine.

- **Windows / Mac:** Download from https://www.docker.com/products/docker-desktop/ and follow the installer.
- **Linux (Ubuntu/Debian):**
  ```bash
  sudo apt-get update && sudo apt-get install docker.io
  sudo usermod -aG docker $USER   # then log out and back in
  ```

Verify Docker is running:
```bash
docker --version
# Expected: Docker version 24.x.x or higher
```

---

## Step 1 — Clone the Repository

```bash
git clone <this-repo-url>
cd labelImg_docker
```

---

## Step 2 — Build the Docker Image

Run this once (or after any changes to the `Dockerfile`). It will take a few minutes the first time.

**Windows (PowerShell):**
```powershell
docker build -t labelimg:latest .
```

**Mac / Linux:**
```bash
docker build -t labelimg:latest .
```

You will see output ending with:
```
naming to docker.io/library/labelimg:latest done
```

> You only need to rebuild if the `Dockerfile` or `data/predefined_classes.txt` changes.

---

## Step 3 — Run the Container

Mount your local image folder into the container at `/data`. Annotations you save inside LabelImg will be written back to that folder on your machine.

**Windows (PowerShell):**
```powershell
docker run -d -p 6080:6080 `
  -v "D:\path\to\your\images:/data" `
  --name labelimg `
  labelimg:latest
```

**Mac / Linux:**
```bash
docker run -d -p 6080:6080 \
  -v "/path/to/your/images:/data" \
  --name labelimg \
  labelimg:latest
```

Replace `D:\path\to\your\images` with the actual folder on your machine that contains the images you want to annotate.

### Example

```powershell
docker run -d -p 6080:6080 `
  -v "D:\Christian\GitHub\SWE-BB-tableparser-version-2\templates\1930\typeA:/data" `
  --name labelimg `
  labelimg:latest
```

---

## Step 4 — Open LabelImg in Your Browser

Wait 3–5 seconds for all services to start, then open:

**http://localhost:6080**

The noVNC viewer will connect automatically and LabelImg will appear in your browser.

> If you see a black screen, wait a few more seconds and refresh the page.

---

## Step 5 — Annotate Images

### Load your images

1. In LabelImg, click **Open Dir** (left panel) or press `Ctrl+U`
2. Navigate to `/data` — this is your mounted image folder
3. Select it — your images will load in the file list

### Set the save directory

1. Click **Change Save Dir** or press `Ctrl+R`
2. Set it to `/data` so annotations are saved alongside your images

### Draw bounding boxes

1. Press `W` to activate the draw tool
2. Click and drag to draw a rectangle around the object
3. A label dialog will appear — select or type the label name
4. Press `Enter` to confirm

### Save

Press `Ctrl+S` to save. A `.xml` file (PascalVOC format) will be created next to the image on your local machine.

---

## Annotation Format

The default format is **PascalVOC** (XML). Each image gets a corresponding `.xml` file saved in the same directory.

To switch to **YOLO** format (`.txt` files), click the format toggle button in the left panel (it shows the current format name — click it to cycle through options).

---

## Predefined Classes

The file `data/predefined_classes.txt` defines the label options available in the dropdown. Edit this file and rebuild the image to update the class list.

Current classes:
```
dog
person
cat
tv
car
meatballs
marinara sauce
tomato soup
chicken noodle soup
french onion soup
chicken breast
ribs
pulled pork
hamburger
cavity
```

To add or change classes, edit `data/predefined_classes.txt` and rebuild:
```powershell
docker build -t labelimg:latest .
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `W` | Draw new bounding box |
| `D` | Next image |
| `A` | Previous image |
| `Ctrl+S` | Save annotation |
| `Ctrl+U` | Open image directory |
| `Ctrl+R` | Change save directory |
| `Ctrl+Z` | Undo |
| `Delete` | Delete selected box |
| `Ctrl+D` | Duplicate selected box |
| `Ctrl++` | Zoom in |
| `Ctrl+-` | Zoom out |
| `↑ ↓ ← →` | Nudge selected box |

---

## Stopping and Restarting

### Stop the container
```powershell
docker stop labelimg
```

### Remove the container (keeps the image)
```powershell
docker rm labelimg
```

### Restart with your image folder
```powershell
docker run -d -p 6080:6080 `
  -v "D:\path\to\your\images:/data" `
  --name labelimg `
  labelimg:latest
```

### Check container status
```powershell
docker ps
```

### View logs (if something looks wrong)
```powershell
docker logs labelimg
```

---

## Troubleshooting

### Port 6080 is already in use
Another container is using port 6080. Stop the existing one:
```powershell
docker stop labelimg; docker rm labelimg
```
Or use a different port:
```powershell
docker run -d -p 7080:6080 -v "D:\path\to\images:/data" --name labelimg labelimg:latest
```
Then open http://localhost:7080 instead.

### Black or blank screen in browser
The services take a few seconds to start. Wait 5 seconds and refresh. If it persists, check logs:
```powershell
docker logs labelimg
```

### LabelImg window does not appear / crashed
```powershell
docker logs labelimg
docker restart labelimg
```

### Annotations not saving to my local folder
Make sure the `-v` mount path is correct and points to an existing folder on your machine. The container path must be `/data`.

### Cannot connect to Docker daemon
Docker Desktop is not running. Open it from the Start menu (Windows) or Applications (Mac) and wait for it to fully start (the whale icon in the system tray stops animating).

### Rebuilding from scratch (clear cache)
```powershell
docker build --no-cache -t labelimg:latest .
```

---

## Architecture Overview

The container runs the following services managed by Supervisor:

| Service | Role |
|---|---|
| Xvfb | Virtual display (no physical monitor needed) |
| x11vnc | VNC server that captures the virtual display |
| websockify | Bridges VNC to WebSocket for browser access |
| openbox | Lightweight window manager |
| labelImg | The annotation application itself |

Access flow: **Browser → noVNC (port 6080) → websockify → x11vnc → Xvfb → LabelImg**
