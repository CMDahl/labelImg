# LabelImg Docker Setup Guide

LabelImg is a graphical image annotation tool for labeling objects in images. This guide will help you run LabelImg in a Docker container, accessible through your web browser - no installation required on your local machine!

## Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Step-by-Step Setup](#step-by-step-setup)
- [Using LabelImg](#using-labelimg)
- [Accessing Your Files](#accessing-your-files)
- [Troubleshooting](#troubleshooting)
- [Tips and Shortcuts](#tips-and-shortcuts)

---

## Prerequisites

### 1. Install Docker Desktop

**Windows:**
1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
2. Run the installer and follow the prompts
3. Restart your computer when prompted
4. Start Docker Desktop from the Start menu
5. Wait for Docker to fully start (the whale icon in the system tray should stop animating)

**Mac:**
1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
2. Open the `.dmg` file and drag Docker to Applications
3. Start Docker from Applications
4. Wait for Docker to fully start

**Linux (Ubuntu/Debian):**
```bash
# Update package index
sudo apt-get update

# Install Docker
sudo apt-get install docker.io docker-compose

# Add your user to the docker group (to run without sudo)
sudo usermod -aG docker $USER

# Log out and back in for the group change to take effect
```

### 2. Verify Docker Installation

Open a terminal (PowerShell on Windows, Terminal on Mac/Linux) and run:
```bash
docker --version
```
You should see something like: `Docker version 24.x.x`

---

## Quick Start

If you're comfortable with Docker, here's the quick version:

```bash
# 1. Create a project folder and navigate to it
mkdir labelimg-docker
cd labelimg-docker

# 2. Create the data folder with predefined classes
mkdir data
echo "line" > data/predefined_classes.txt

# 3. Download/create the Dockerfile (see Step-by-Step Setup below)

# 4. Build and run
docker build -t labelimg .
docker run -it --rm -p 6080:6080 -v C:\:/mnt/c labelimg   # Windows
docker run -it --rm -p 6080:6080 -v /:/mnt/host labelimg  # Mac/Linux

# 5. Open browser to: http://localhost:6080/vnc.html?resize=scale&autoconnect=true
```

---

## Step-by-Step Setup

### Step 1: Create Project Folder

Create a new folder for this project. Open your terminal and run:

**Windows (PowerShell):**
```powershell
mkdir C:\labelimg-docker
cd C:\labelimg-docker
```

**Mac/Linux:**
```bash
mkdir ~/labelimg-docker
cd ~/labelimg-docker
```

### Step 2: Create the Data Folder

Create a `data` folder that will contain your predefined class labels:

```bash
mkdir data
```

### Step 3: Create the Predefined Classes File

Create a file called `predefined_classes.txt` inside the `data` folder. This file contains the labels you'll use for annotation (one per line).

**Windows (PowerShell):**
```powershell
@"
line
"@ | Out-File -FilePath data\predefined_classes.txt -Encoding utf8
```

**Mac/Linux:**
```bash
echo "line" > data/predefined_classes.txt
```

> **Note:** If you need additional classes, add them on separate lines in this file.

### Step 4: Create the Dockerfile

Create a file named `Dockerfile` (no extension) in your project folder with the following content:

**Windows (PowerShell):**
```powershell
@"
# Dockerfile for LabelImg - Graphical Image Annotation Tool
# Uses Python 3, PyQt5, and noVNC for browser-based access

FROM python:3.9-slim

# Install system dependencies for PyQt5, X11, VNC, and noVNC
RUN apt-get update && apt-get install -y --no-install-recommends \
    # X11 and Qt dependencies
    libgl1 \
    libegl1 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcb-glx0 \
    libxcb-xinerama0 \
    libxkbcommon0 \
    libxkbcommon-x11-0 \
    libdbus-1-3 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-shm0 \
    libxcb-sync1 \
    libxcb-xfixes0 \
    libxcb-xkb1 \
    libxcb-cursor0 \
    libfontconfig1 \
    libfreetype6 \
    libxi6 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxtst6 \
    # VNC and virtual display
    xvfb \
    x11vnc \
    # noVNC for web access
    novnc \
    websockify \
    # Window manager
    openbox \
    # Utilities
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install labelImg from PyPI
RUN pip install --no-cache-dir labelImg

# Copy predefined classes file
COPY data/predefined_classes.txt /app/data/predefined_classes.txt

# Create supervisor config
RUN mkdir -p /var/log/supervisor
COPY <<EOF /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:xvfb]
command=/usr/bin/Xvfb :1 -screen 0 1920x1080x24
autorestart=true
priority=100

[program:x11vnc]
command=/usr/bin/x11vnc -display :1 -forever -shared -rfbport 5900 -nopw -scale 1.0
autorestart=true
priority=200

[program:novnc]
command=/usr/share/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080
autorestart=true
priority=300

[program:openbox]
command=/usr/bin/openbox
environment=DISPLAY=":1"
autorestart=true
priority=400

[program:labelimg]
command=/usr/local/bin/labelImg
environment=DISPLAY=":1",QT_X11_NO_MITSHM="1"
autorestart=false
priority=500
startsecs=3
EOF

# Expose noVNC web port
EXPOSE 6080

# Set environment variables
ENV DISPLAY=:1
ENV QT_X11_NO_MITSHM=1

# Run supervisor to manage all services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
"@ | Out-File -FilePath Dockerfile -Encoding utf8
```

**Mac/Linux:**
Simply copy the Dockerfile content from the repository or create it manually with a text editor.

### Step 5: Verify Your Folder Structure

Your project folder should now look like this:
```
labelimg-docker/
├── Dockerfile
└── data/
    └── predefined_classes.txt
```

### Step 6: Build the Docker Image

This step downloads and builds everything needed. It may take a few minutes the first time.

```bash
docker build -t labelimg .
```

You should see output ending with:
```
Successfully built xxxxxxxxxx
Successfully tagged labelimg:latest
```

### Step 7: Run the Container

**Windows - Mount entire C: drive:**
```powershell
docker run -it --rm -p 6080:6080 -v C:\:/mnt/c labelimg
```

**Windows - Mount specific folder:**
```powershell
docker run -it --rm -p 6080:6080 -v C:\Users\YourName\Pictures:/mnt/images labelimg
```

**Mac - Mount home directory:**
```bash
docker run -it --rm -p 6080:6080 -v ~:/mnt/home labelimg
```

**Linux - Mount home directory:**
```bash
docker run -it --rm -p 6080:6080 -v /home/$USER:/mnt/home labelimg
```

### Step 8: Access LabelImg in Your Browser

Open your web browser and go to:

**http://localhost:6080/vnc.html?resize=scale&autoconnect=true**

You should see LabelImg running in your browser!

---

## Using LabelImg

### Opening Images

1. Click **"Open Dir"** in the left toolbar (or press `Ctrl+U`)
2. Navigate to your mounted folder:
   - Windows: `/mnt/c/Users/YourName/Pictures/...`
   - Mac/Linux: `/mnt/home/Pictures/...`
3. Select the folder containing your images

### Creating Annotations

1. Click **"Create RectBox"** (or press `W`)
2. Click and drag to draw a rectangle around the object
3. Enter the label name (or select from the dropdown)
4. Press `Enter` to confirm

### Saving Annotations

1. Click **"Save"** (or press `Ctrl+S`)
2. Annotations are saved as XML files (PascalVOC format) in the same folder as your images
3. Each image will have a corresponding `.xml` file with the same name

> **Note:** Make sure the format button below "Save" shows **"PascalVOC"**. This is the default XML format.

---

## Accessing Your Files

When you mount your drive/folder, it becomes accessible inside the container:

| Host Location | Container Location |
|---------------|-------------------|
| `C:\` (Windows) | `/mnt/c` |
| `C:\Users\Name\Pictures` | `/mnt/images` (if mounted specifically) |
| `/home/user` (Linux/Mac) | `/mnt/home` |

Your annotations will be saved alongside your images, so they'll be accessible on your host machine even after stopping the container.

---

## Troubleshooting

### "Port 6080 is already in use"

Another container or application is using port 6080. Either:
1. Stop the other container: `docker ps` then `docker stop <container_id>`
2. Use a different port: `docker run -it --rm -p 8080:6080 -v C:\:/mnt/c labelimg`
   Then access via: http://localhost:8080/vnc.html?resize=scale&autoconnect=true

### "Cannot connect to the Docker daemon"

Make sure Docker Desktop is running. Look for the whale icon in your system tray.

### Black screen in browser

Wait a few seconds - the services are still starting. Refresh the page if needed.

### LabelImg window is too small

Make sure you're using the URL with resize parameter:
`http://localhost:6080/vnc.html?resize=scale&autoconnect=true`

### Permission denied when saving files

On Linux, you may need to run with your user ID:
```bash
docker run -it --rm -p 6080:6080 -u $(id -u):$(id -g) -v /home/$USER:/mnt/home labelimg
```

### Docker build fails

1. Make sure Docker Desktop is running
2. Check your internet connection
3. Try building again: `docker build --no-cache -t labelimg .`

---

## Tips and Shortcuts

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `W` | Create a new bounding box |
| `D` | Next image |
| `A` | Previous image |
| `Ctrl+S` | Save |
| `Ctrl+D` | Duplicate current box |
| `Delete` | Delete selected box |
| `Ctrl+U` | Load all images from directory |
| `Ctrl++` | Zoom in |
| `Ctrl+-` | Zoom out |
| `↑↓←→` | Move selected box |

### Best Practices

1. **Organize your images** in a dedicated folder before starting
2. **Edit `predefined_classes.txt`** to match your project's labels before building
3. **Save frequently** (`Ctrl+S`) to avoid losing work
4. **Use keyboard shortcuts** to speed up your workflow

---

## Stopping the Container

Press `Ctrl+C` in the terminal where the container is running, or open a new terminal and run:
```bash
docker stop $(docker ps -q --filter ancestor=labelimg)
```

---

## Rebuilding After Changes

If you modify `predefined_classes.txt` or the `Dockerfile`:

```bash
docker build -t labelimg .
```

Then run the container again.

---

## Support

- **LabelImg GitHub:** https://github.com/HumanSignal/labelImg
- **Docker Documentation:** https://docs.docker.com/
- **noVNC:** https://novnc.com/

---

Happy Labeling! 🏷️
