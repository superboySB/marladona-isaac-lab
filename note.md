# MARLadona notes

## Clone
```sh
git clone https://github.com/superboySB/marladona-isaac-lab.git
cd marladona-isaac-lab
```

## Docker setup (Isaac Sim 4.5 + Isaac Lab 2.0.2)
Prereqs: Docker, NVIDIA Container Toolkit, GPU driver, and X11 if you want GUI.

### Build image
Run from the repo root so Docker can copy `source/`.
```sh
docker build -f docker/simulation.dockerfile \
  --build-arg ISAACSIM_VERSION=4.5.0 \
  --build-arg ISAACLAB_REPO=https://github.com/isaac-sim/IsaacLab.git \
  --build-arg ISAACLAB_REF=v2.0.2 \
  --network=host --progress=plain \
  -t marladona_image:sim .
```
Optional: set a custom base image with `--build-arg ISAACSIM_BASE_IMAGE=nvcr.io/nvidia/isaac-sim`.

### Run container (GUI)
```sh
xhost +local:root

docker run --name marladona-sim -itd --privileged --gpus all --network host \
  --entrypoint bash \
  -e ACCEPT_EULA=Y -e PRIVACY_CONSENT=Y \
  -e DISPLAY -e QT_X11_NO_MITSHM=1 \
  -e OMNI_KIT_ALLOW_ROOT=1 \
  -v $HOME/.Xauthority:/root/.Xauthority \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ~/docker/isaac-sim-4.5/cache/kit:/isaac-sim/kit/cache:rw \
  -v ~/docker/isaac-sim-4.5/cache/ov:/root/.cache/ov:rw \
  -v ~/docker/isaac-sim-4.5/cache/pip:/root/.cache/pip:rw \
  -v ~/docker/isaac-sim-4.5/cache/glcache:/root/.cache/nvidia/GLCache:rw \
  -v ~/docker/isaac-sim-4.5/cache/computecache:/root/.nv/ComputeCache:rw \
  -v ~/docker/isaac-sim-4.5/logs:/root/.nvidia-omniverse/logs:rw \
  -v ~/docker/isaac-sim-4.5/data:/root/.local/share/ov/data:rw \
  -v ~/docker/isaac-sim-4.5/documents:/root/Documents:rw \
  -v /home/dzp/projects/marladona-isaac-lab:/workspace/marladona-isaac-lab \
  marladona_image:sim

xhost +

docker exec -it marladona-sim /bin/bash
```

### Container usage
The scripts load `source/` directly, so you can run without manual `pip install -e`:
```sh
# Train
python scripts/rsl_rl/train.py --headless --task=Isaac-Soccer-v0

# Play (example policy)
python scripts/rsl_rl/play.py --task=Isaac-Soccer-Play-v0 \
  --experiment_name=00_example_policies \
  --load_run=24_09_28_11_56_41_3v3
```
Logs go to `wks_logs/` by default.

## Server scripts (sb-RL-172)
These scripts use MARLadona-specific names/paths and do not touch CrazyRL resources.

1) Clean remote container/image:
```sh
tools/marladona_clean_server.sh sb-RL-172 20260121
```

2) Deploy to server (builds/exports image from local container `marladona-train` and uploads project):
```sh
tools/marladona_deploy_on_server.sh sb-RL-172 20260121 device=all
```
Optional envs: `LOCAL_PROJECT_PATH`, `LOCAL_TMP_DIR`, `REMOTE_BASE_DIR`, `REMOTE_ISAACSIM_CACHE`.
Local container name is fixed to `marladona-train` in the script; start your container with that name before deploying.

3) Download logs (from remote `.../marladona-isaac-lab-<date>/wks_logs`):
```sh
tools/marladona_download_from_server.sh sb-RL-172 20260121
```
