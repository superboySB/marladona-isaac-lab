# syntax=docker/dockerfile:1.4

ARG ISAACSIM_BASE_IMAGE=nvcr.io/nvidia/isaac-sim
ARG ISAACSIM_VERSION=4.5.0
FROM ${ISAACSIM_BASE_IMAGE}:${ISAACSIM_VERSION} AS simulation

ARG ISAACSIM_ROOT_PATH=/isaac-sim
ARG ISAACLAB_PATH=/workspace/isaaclab
ARG DOCKER_USER_HOME=/root
ARG WORKSPACE_PATH=/workspace/marladona-isaac-lab
ARG ISAACLAB_REPO=https://github.com/isaac-sim/IsaacLab.git
ARG ISAACLAB_REF=v2.0.2

ENV ISAACSIM_VERSION=${ISAACSIM_VERSION} \
    ISAACSIM_ROOT_PATH=${ISAACSIM_ROOT_PATH} \
    ISAACLAB_PATH=${ISAACLAB_PATH} \
    DOCKER_USER_HOME=${DOCKER_USER_HOME} \
    WORKSPACE_PATH=${WORKSPACE_PATH} \
    ISAACSIM_PATH=${ISAACLAB_PATH}/_isaac_sim \
    OMNI_KIT_ALLOW_ROOT=1 \
    http_proxy=http://127.0.0.1:8889 \
    https_proxy=http://127.0.0.1:8889 \
    HTTP_PROXY=http://127.0.0.1:8889 \
    HTTPS_PROXY=http://127.0.0.1:8889 \
    no_proxy=localhost,127.0.0.1,::1 \
    NO_PROXY=localhost,127.0.0.1,::1 \
    LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

USER root

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    libglib2.0-0 \
    libice6 \
    libsm6 \
    libx11-xcb1 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-xfixes0 \
    libxcb-xinerama0 \
    libxcb-xinput0 \
    libxcb1 \
    libxext6 \
    libxkbcommon-x11-0 \
    libxrender1 \
    ncurses-term \
    tmux \
    gedit \
    vim && \
    apt -y autoremove && apt clean autoclean && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --branch ${ISAACLAB_REF} --depth 1 ${ISAACLAB_REPO} ${ISAACLAB_PATH} && \
    rm -rf ${ISAACLAB_PATH}/.git

RUN chmod +x ${ISAACLAB_PATH}/isaaclab.sh

RUN ln -sf ${ISAACSIM_ROOT_PATH} ${ISAACLAB_PATH}/_isaac_sim

RUN printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    "exec ${ISAACLAB_PATH}/_isaac_sim/python.sh \"\$@\"" \
    > /usr/local/bin/python && \
    chmod +x /usr/local/bin/python && \
    ln -sf /usr/local/bin/python /usr/local/bin/python3

RUN ${ISAACLAB_PATH}/isaaclab.sh -p -m pip install toml PyQt5

RUN ${ISAACLAB_PATH}/_isaac_sim/python.sh -m pip install --upgrade pip && \
    ${ISAACLAB_PATH}/_isaac_sim/python.sh -m pip install "sympy>=1.13.3"

RUN --mount=type=cache,target=/var/cache/apt \
    ${ISAACLAB_PATH}/isaaclab.sh -p ${ISAACLAB_PATH}/tools/install_deps.py apt ${ISAACLAB_PATH}/source && \
    apt -y autoremove && apt clean autoclean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${ISAACSIM_ROOT_PATH}/kit/cache && \
    mkdir -p ${DOCKER_USER_HOME}/.cache/ov && \
    mkdir -p ${DOCKER_USER_HOME}/.cache/pip && \
    mkdir -p ${DOCKER_USER_HOME}/.cache/nvidia/GLCache && \
    mkdir -p ${DOCKER_USER_HOME}/.nv/ComputeCache && \
    mkdir -p ${DOCKER_USER_HOME}/.nvidia-omniverse/logs && \
    mkdir -p ${DOCKER_USER_HOME}/.local/share/ov/data && \
    mkdir -p ${DOCKER_USER_HOME}/Documents

RUN touch /bin/nvidia-smi && \
    touch /bin/nvidia-debugdump && \
    touch /bin/nvidia-persistenced && \
    touch /bin/nvidia-cuda-mps-control && \
    touch /bin/nvidia-cuda-mps-server && \
    touch /etc/localtime && \
    mkdir -p /var/run/nvidia-persistenced && \
    touch /var/run/nvidia-persistenced/socket

RUN --mount=type=cache,target=${DOCKER_USER_HOME}/.cache/pip \
    ${ISAACLAB_PATH}/isaaclab.sh --install

WORKDIR ${WORKSPACE_PATH}

# Isaac Sim extensions still rely on NumPy 1.x ABI.
RUN ${ISAACLAB_PATH}/_isaac_sim/python.sh -m pip install --upgrade --no-cache-dir "numpy<2"

RUN echo "export ISAACLAB_PATH=${ISAACLAB_PATH}" >> ${HOME}/.bashrc && \
    echo "alias isaaclab=${ISAACLAB_PATH}/isaaclab.sh" >> ${HOME}/.bashrc && \
    echo "alias python=${ISAACLAB_PATH}/_isaac_sim/python.sh" >> ${HOME}/.bashrc && \
    echo "alias python3=${ISAACLAB_PATH}/_isaac_sim/python.sh" >> ${HOME}/.bashrc && \
    echo "alias pip='${ISAACLAB_PATH}/_isaac_sim/python.sh -m pip'" >> ${HOME}/.bashrc && \
    echo "alias pip3='${ISAACLAB_PATH}/_isaac_sim/python.sh -m pip'" >> ${HOME}/.bashrc && \
    echo "export PYTHONPATH=${WORKSPACE_PATH}:${ISAACLAB_PATH}:\$PYTHONPATH" >> ${HOME}/.bashrc && \
    echo "export ENABLE_EGL=1" >> ${HOME}/.bashrc && \
    echo "export KIT_ENABLE_VULKAN_HEADLESS=1" >> ${HOME}/.bashrc && \
    echo "export TZ=$(date +%Z)" >> ${HOME}/.bashrc

ENTRYPOINT ["/bin/bash"]

# TODO: If you built with proxy and want to move the image, clear proxy envs.
# ENV http_proxy=
# ENV https_proxy=
# ENV no_proxy=
