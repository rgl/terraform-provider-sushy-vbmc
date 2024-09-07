# syntax=docker/dockerfile:1.9
FROM debian:12-slim
# see https://opendev.org/openstack/sushy-tools/src/tag/1.3.0/requirements.txt
RUN <<EOF
apt-get update -y
apt-get install -y --no-install-recommends \
    python3-flask \
    python3-ironic \
    python3-libvirt \
    python3-pbr \
    python3-pip \
    python3-requests \
    python3-tenacity
rm -rf /var/lib/apt/lists/*
EOF
COPY requirements.txt .
RUN pip3 install --break-system-packages --no-cache-dir -r requirements.txt
COPY . .
ENTRYPOINT ["./entrypoint.sh"]