#
# Dockerfile for exllama_v2 (see config.py for package configuration)
#
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG TORCH_CUDA_ARCH_LIST \
    EXLLAMA2_REPO=turboderp/exllamav2 \
    EXLLAMA2_BRANCH=master

ADD https://api.github.com/repos/${EXLLAMA2_REPO}/git/refs/heads/${EXLLAMA2_BRANCH} /tmp/exllama2_version.json

RUN set -ex \
    && git clone --branch=${EXLLAMA2_BRANCH} --depth=1 https://github.com/${EXLLAMA2_REPO} /opt/exllamav2 \
    && sed 's|torch.*|torch|g' -i /opt/exllamav2/requirements.txt \
    && sed 's|"torch.*"|"torch"|g' -i /opt/exllamav2/setup.py \
    && sed 's|\[\"cublas\"\] if windows else \[\]|\[\"cublas\"\]|g' -i /opt/exllamav2/setup.py \
    \
    && cd /opt/exllamav2 \
    && python3 setup.py --verbose bdist_wheel --dist-dir /opt \
    \
    && pip3 install --no-cache-dir --verbose /opt/exllamav2*.whl \
    # this will build cuda_ext.py to ~/.cache/torch_extensions/ \
    && python3 test_inference.py --help \
    \
    && pip3 show exllamav2 \
    && python3 -c 'import exllamav2'
