FROM nvidia/cuda:11.2.2-base-ubuntu20.04 as base

LABEL maintainer=elisabettai

# simcore-user uid=8004(${SC_USER_NAME}) gid=8004(${SC_USER_NAME}) groups=8004(${SC_USER_NAME})
ENV SC_USER_ID 8004
ENV SC_USER_NAME scu
RUN adduser --uid ${SC_USER_ID} --disabled-password --gecos "" --shell /bin/sh --home /home/${SC_USER_NAME} ${SC_USER_NAME}

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    jq \
    git \
    curl \
    python3 \
    python3-pip \
    && rm --recursive --force /var/lib/apt/lists/*

# -------------------------- Build stage -------------------
# Installs AxonDeepSeg and dependencies (src/requirements.txt)
#
# + /build             WORKDIR
#

FROM base as build

ENV SC_BUILD_TARGET build

WORKDIR /build

COPY --chown=${SC_USER_NAME}:${SC_USER_NAME} src/ src/

RUN pip --no-cache --quiet install --upgrade pip && \
    pip install -r src/requirements.txt

# Clone and install AxonDeepSeg
ENV ADS_SHA=9ab16452a1411788e845e5c1e2cd2301ba5e81b5
RUN git clone https://github.com/neuropoly/axondeepseg.git && \
    cd axondeepseg && \
    git checkout -b release ${ADS_SHA} && \
    pip install -e . && \
    axondeepseg_test

# Install torch for AxonDeepSeg+GPU.
# Versions from  https://pytorch.org/get-started/previous-versions/. No CUDA 11.2 mentioned, so using latest torch version for CUDA 11.3
RUN pip install torch==1.12.0+cu113 torchvision==0.13.0+cu113  --extra-index-url https://download.pytorch.org/whl/cu113

# ------------------------------------------------------------------------------------

# --------------------------Production stage -------------------
# Final cleanup up to reduce image size and startup setup
# Runs as ${SC_USER_NAME} (non-root user)

FROM base as production

ENV SC_BUILD_TARGET production
ENV SC_BOOT_MODE production


ENV INPUT_FOLDER="/input" \
    OUTPUT_FOLDER="/output"


WORKDIR /home/${SC_USER_NAME}

# copy lib for python packages, bin for axondeepseg binaries, and build for AxonDeepSeg source
COPY --from=build --chown=${SC_USER_NAME}:${SC_USER_NAME} /usr/local/lib /usr/local/lib
COPY --from=build --chown=${SC_USER_NAME}:${SC_USER_NAME} /usr/local/bin /usr/local/bin
COPY --from=build --chown=${SC_USER_NAME}:${SC_USER_NAME} /build /build

# ------------------------------------------------------------------------------------
# Install runtime dependencies
RUN apt-get update \
&& apt-get -y install --no-install-recommends \
    zip \
&& rm -rf /var/lib/apt/lists/*
# ------------------------------------------------------------------------------------

# copy docker bootup scripts
COPY --chown=${SC_USER_NAME}:${SC_USER_NAME} docker/custom/*.sh docker/
# copy simcore service cli
COPY --chown=${SC_USER_NAME}:${SC_USER_NAME} service.cli/ service.cli/
# necessary to be able to call run directly without sh in front
ENV PATH="/home/${SC_USER_NAME}/service.cli:${PATH}"

# ------------------------------------------------------------------------------------
#TODO:
# uncomment and provide a healtchecker if possible
# HEALTHCHECK --interval=30s \
#             --timeout=120s \
#             --start-period=30s \
#             --retries=3 \
#             CMD ["healthchecker app"]
# ------------------------------------------------------------------------------------

ENTRYPOINT [ "/bin/sh", "docker/entrypoint.sh", "/bin/sh", "-c" ]
CMD ["run"]
