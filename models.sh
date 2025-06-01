#!/bin/bash
#1. RM Comfy folder
#2. DL backup
#3. PIP install latest from backup /.venv-backups/{source-instance-id}/
#pip install --no-cache-dir -r venv-main-latest.txt workspace/

wget https://fsn1.your-objectstorage.com/sf-models/checkpoints/bigLust_v16.safetensors
wget https://fsn1.your-objectstorage.com/sf-models/checkpoints/realismEngineSDXL_v30VAE.safetensors
