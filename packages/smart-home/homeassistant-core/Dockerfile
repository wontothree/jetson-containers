#---
# name: homeassistant-core
# group: smart-home
# config: config.py
# requires: '>=34.1.0'
# docs: README.md
# depends: [build-essential, ffmpeg]
# test: [test_ciso8601.py, test_psutil_home_assistant.py, test_homeassistant.py]
# notes: The `homeassistant-core` wheel that's build is saved in `/usr/src/homeassistant`
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG HA_BRANCH \
    BUILD_ARCH="aarch64" \
    BASHIO_VERSION=0.16.2 \
    TEMPIO_VERSION=2021.09.0 \
    S6_OVERLAY_VERSION=3.1.6.2

ENV S6_ARCH="${BUILD_ARCH}" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_SERVICES_READYTIME=50 \
    S6_SERVICES_GRACETIME=240000 \
    UV_SYSTEM_PYTHON=true

# Set shell
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

# Base system
WORKDIR /usr/src

COPY *.diff /tmp/

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        jq \
        xz-utils \
        autoconf \
        libpcap0.8 \
    \
    && curl -L -f -s "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" \
        | tar Jxvf - -C / \
    && curl -L -f -s "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
        | tar Jxvf - -C / \
    && curl -L -f -s "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz" \
        | tar Jxvf - -C / \
    && curl -L -f -s "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz" \
        | tar Jxvf - -C / \
    && mkdir -p /etc/fix-attrs.d \
    && mkdir -p /etc/services.d \
    \
    && curl -L -f -s -o /usr/bin/tempio \
        "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${BUILD_ARCH}" \
    && chmod a+x /usr/bin/tempio \
    \
    && mkdir -p /usr/src/bashio \
    && curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
        | tar -xzf - --strip 1 -C /usr/src/bashio \
    && mv /usr/src/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/src/*

# Install uv
RUN pip3 install --no-cache-dir --verbose uv==0.1.27

# Install ciso8601
RUN git clone https://github.com/closeio/ciso8601 /tmp/ciso8601 \
    && git -C /tmp/ciso8601 apply /tmp/ciso8601-patch.diff \
    && git -C /tmp/ciso8601 diff \
    && pip3 wheel --wheel-dir=/opt/ --no-deps --verbose /tmp/ciso8601 \
    && pip3 install --no-cache-dir --verbose /opt/ciso8601*.whl \
    && pip3 show ciso8601 \
    && python3 -c 'import ciso8601; print(ciso8601.__version__);' \
    && rm -rf /tmp/ciso8601

# Install psutil-home-assistant
RUN git clone https://github.com/home-assistant-libs/psutil-home-assistant /tmp/psutil-home-assistant \
    && pip3 wheel --wheel-dir=/opt/ --no-deps --verbose /tmp/psutil-home-assistant \
    && pip3 install --no-cache-dir --verbose /opt/psutil_home_assistant*.whl \
    && pip3 show psutil-home-assistant \
    && python3 -c 'import psutil_home_assistant;' \
    && rm -rf /tmp/psutil-home-assistant

RUN echo "HA_BRANCH: ${HA_BRANCH}" \
    && python3 --version \
    && pip3 install --no-cache-dir --ignore-installed blinker \
    && git clone --branch=${HA_BRANCH} https://github.com/home-assistant/core homeassistant \
    \
    && uv pip --version \
    && uv pip install --no-cache-dir --verbose -r homeassistant/requirements.txt

RUN if ls homeassistant/home_assistant_*.whl 1> /dev/null 2>&1; then \
        uv pip install --no-cache-dir --verbose homeassistant/home_assistant_*.whl; \
    fi \
    && if [ "${BUILD_ARCH}" = "i386" ]; then \
        LD_PRELOAD="${LD_PRELOAD}:/usr/lib/aarch64-linux-gnu/libjemalloc.so.2" \
        MALLOC_CONF="background_thread:true,metadata_thp:auto,dirty_decay_ms:20000,muzzy_decay_ms:20000" \
        linux32 uv pip install \
            --no-cache-dir \
            --verbose \
            -r homeassistant/requirements_all.txt; \
    else \
        LD_PRELOAD="${LD_PRELOAD}:/usr/lib/aarch64-linux-gnu/libjemalloc.so.2" \
        MALLOC_CONF="background_thread:true,metadata_thp:auto,dirty_decay_ms:20000,muzzy_decay_ms:20000" \
        uv pip install \
            --no-cache-dir \
            --verbose \
            -r homeassistant/requirements_all.txt; \
    fi \
    && uv pip install -e homeassistant \
    && python3 -m compileall homeassistant

# Home Assistant S6-Overlay
RUN cp -r homeassistant/rootfs/* /

WORKDIR /config

ENTRYPOINT ["/init"]
