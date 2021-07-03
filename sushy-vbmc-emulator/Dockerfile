FROM debian:buster-slim
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends python3-pip python3-libvirt
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
COPY . .
ENTRYPOINT ["./entrypoint.sh"]