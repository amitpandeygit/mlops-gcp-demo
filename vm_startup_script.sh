#!/bin/bash
# Paste this into "Startup script" when creating the VM.
# It installs MLflow and starts it on port 5000. It runs again on every reboot.
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile
fi
swapon /swapfile 2>/dev/null
if [ ! -x /opt/mlenv/bin/mlflow ]; then
  rm -rf /opt/mlenv
  apt-get -o DPkg::Lock::Timeout=600 update -y
  apt-get -o DPkg::Lock::Timeout=600 install -y python3-venv
  python3 -m venv /opt/mlenv
  /opt/mlenv/bin/pip install mlflow==2.19.0 sqlalchemy==2.0.36 google-cloud-storage
fi
PROJECT=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/project/project-id)
nohup /opt/mlenv/bin/mlflow server --host 0.0.0.0 --port 5000 \
  --backend-store-uri sqlite:////opt/mlflow.db \
  --serve-artifacts --artifacts-destination gs://$PROJECT-mlops-demo/mlflow-artifacts \
  > /var/log/mlflow.log 2>&1 &
