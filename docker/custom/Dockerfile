FROM nvidia/cudagl:11.2.2-devel-ubuntu20.04 as base
#
#  USAGE:
#     cd services/axondeepseg-runner
#     docker build -f Dockerfile -t axondeepseg-runner:prod --target production ../../
#     docker run axondeepseg-runner:prod
#

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
    && rm --recursive --force /var/lib/apt/lists/*

# -------------------------- Build stage -------------------
# Installs build/package management tools and third party dependencies
#
# + /build             WORKDIR
#

FROM base as build

ENV SC_BUILD_TARGET build

WORKDIR /build

# Install AxonDeepSec from doc instructions, via miniconda: https://axondeepseg.readthedocs.io/en/latest/documentation.html#installation
# Change path to include conda commands

#ARG PATH="/opt/miniconda3/bin:${PATH}"

ENV CONDA_DIR=/opt/miniconda3/

RUN curl \
    https://repo.anaconda.com/miniconda/Miniconda3-py38_23.10.0-1-Linux-x86_64.sh -o miniconda.sh && \
    bash miniconda.sh -b -p ${CONDA_DIR} \
    && rm -f Miniconda3-latest-Linux-x86_64.sh

ENV ADS_SHA=9ab16452a1411788e845e5c1e2cd2301ba5e81b5

ENV PATH="/opt/miniconda3/bin:${PATH}"

# Create conda env for axondeepseg
RUN git clone https://github.com/neuropoly/axondeepseg.git && \
    cd axondeepseg && \
    git checkout -b release ${ADS_SHA} && \
    conda init bash && \
    conda env create

# "Activate" the conda env
SHELL ["conda", "run", "-n", "ads_venv", "/bin/bash", "-c" ]

RUN  cd axondeepseg && \
     pip install -e . plugins/ && \
     axondeepseg_test

# Install torch for AxonDeepSeg+GPU
# Versions from  https://pytorch.org/get-started/previous-versions/. No CUDA 11.2 mentioned, so using latest torch version for CUDA 11.3
#RUN conda install pytorch==1.12.0 torchvision==0.13.0 torchaudio==0.12.0 cudatoolkit=11.3 -c pytorch
RUN pip install torch==1.12.0+cu113 torchvision==0.13.0+cu113 torchaudio==0.12.0 --extra-index-url https://download.pytorch.org/whl/cu113

# defines the output of the build
#RUN mkdir --parents /build/bin
# copy src code
#COPY --chown=${SC_USER_NAME}:${SC_USER_NAME} src/axondeepseg_runner src/axondeepseg_runner
# ------------------------------------------------------------------------------------
#TODO:
# uncomment and adapt if build steps are necessary
# RUN cp -R src/axondeepseg_runner/* /build/bin
# ------------------------------------------------------------------------------------

# --------------------------Production stage -------------------
# Final cleanup up to reduce image size and startup setup
# Runs as ${SC_USER_NAME} (non-root user)
#
#  + /home/${SC_USER_NAME}     $HOME = WORKDIR
#    + axondeepseg_runner [${SC_USER_NAME}:${SC_USER_NAME}]
#    + docker [${SC_USER_NAME}:${SC_USER_NAME}]
#    + service.cli [${SC_USER_NAME}:${SC_USER_NAME}]
#
FROM base as production

ENV SC_BUILD_TARGET production
ENV SC_BOOT_MODE production


ENV INPUT_FOLDER="/input" \
    OUTPUT_FOLDER="/output"


WORKDIR /home/${SC_USER_NAME}



# copy conda env where AxonDeepSeg is installed from build
COPY --from=build --chown=${SC_USER_NAME}:${SC_USER_NAME} /opt/miniconda3/. /opt/miniconda3/
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
