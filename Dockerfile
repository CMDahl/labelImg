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
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/share/novnc/vnc_auto.html /usr/share/novnc/index.html

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
user=root
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
command=/usr/bin/websockify --web /usr/share/novnc 6080 localhost:5900
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
