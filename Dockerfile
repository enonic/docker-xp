################################################################################
# Build stage 1 `downloader`:
#
# This stage was added because building linux/arm64 images under qemu resulted
# in segmentation faults while downloading artifacts.
################################################################################

ARG build_base_image
FROM alpine as downloader

# Set downloader environment
ARG build_distro_version
ARG build_distro_path
ENV \
  XP_VERSION="$build_distro_version" \
  XP_DISTRO_PATH=${build_distro_path:-"https://repo.enonic.com/public/com/enonic/xp/enonic-xp-generic/$build_distro_version/enonic-xp-generic-$build_distro_version.tgz"}
WORKDIR /tmp

# Download and unzip XP
ARG build_distro_version
RUN mkdir --parents /tmp/xp; \
    cd /tmp/xp; \
    wget -O- "$XP_DISTRO_PATH" | tar --strip-components=1 -xz

# old JNA library doesn't support the arrch64 platform, but the current elasticsearch version needs it. Fortunately, it's not essential and can be removed.
RUN set -eux; \
    dpkgArch=`uname -m`; \
    echo `uname -m`; \
    if [ "$dpkgArch" = "aarch64" ]; then \
      rm -f /tmp/xp/lib/jna-4.1.0.jar; \
    fi;

# Download and unzip jattach source
RUN mkdir --parents /tmp/jattach; \
    cd /tmp/jattach; \
    wget -O- "https://github.com/apangin/jattach/archive/refs/tags/v2.1.tar.gz" | tar --strip-components=1 -xz

################################################################################
# Build stage 2 `builder`:
#
# Here we compile jattach, add folders missing from the distro and
# set permissions.
################################################################################
ARG build_base_image
FROM $build_base_image as builder

# Set builder environment
ARG build_distro_version
ENV \
  DISTRO_FOLDER="/tmp/xp" \
  JATTACH_FOLDER="/tmp/jattach" \
  BIN_FOLDER="/tmp/bin"

# Get needed build dependencies
RUN \
  DEBIAN_FRONTEND="noninteractive" \
  apt-get -qq update && \
  apt-get -qq upgrade && \
  apt-get -qq install -y build-essential

# Copy in downloaded files
COPY --from=downloader /tmp /tmp

# Create standard folders so docker will preserve
# folder permissions when mounting named volumes
ENV CREATE_DIRS="config,data,deploy,logs,repo/blob,repo/index,snapshots,work"
RUN bash -c "mkdir -p ${DISTRO_FOLDER}/home/{$CREATE_DIRS}"
RUN mkdir ${BIN_FOLDER}

# Compile jattach to do heap and thread dumps
RUN \
  cd ${JATTACH_FOLDER} && \
  make all && \
  chmod +x ${JATTACH_FOLDER}/build/jattach && \
  cp ${JATTACH_FOLDER}/build/jattach ${BIN_FOLDER}/jattach

# Copy in scripts to bin folder
COPY bin/* ${BIN_FOLDER}/

# Openshift overrides USER and uses ones with randomly uid>1024 and gid=0.
# Allow ENTRYPOINT (and XP) to run even with a different user. So we change
# the group to 0 and give the group same permissions as owner for
# both server files and binaries
RUN \
  chgrp -R 0 ${DISTRO_FOLDER} && \
  chmod -R g=u ${DISTRO_FOLDER} && \
  chgrp -R 0 ${BIN_FOLDER} && \
  chmod -R g=u ${BIN_FOLDER}

# Add the standard bash profile to XP ROOT
RUN \
  cp -R /etc/skel/. ${DISTRO_FOLDER}/

################################################################################
# Build stage 3 (the actual XP image):
################################################################################

ARG build_base_image
FROM $build_base_image

# Setup locale
RUN locale-gen en_US.UTF-8
ENV \
  LANG="en_US.UTF-8" \
  LANGUAGE="en_US:en" \
  LC_ALL="en_US.UTF-8"

# Setup environment
ARG build_distro_version
ENV \
  XP_DISTRO_VERSION="$build_distro_version" \
  XP_ROOT="/enonic-xp" \
  XP_HOME="/enonic-xp/home" \
  XP_USER="enonic-xp" \
  XP_UID="1337"
ENV PATH=$PATH:$XP_ROOT/bin

# Set labels
ARG build_date
LABEL \
  org.label-schema.build-date="${build_date}" \
  org.label-schema.license="GPL-3.0" \
  org.label-schema.name="Enonic XP" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.url="https://enonic.com/platform" \
  org.label-schema.usage="https://developer.enonic.com/" \
  org.label-schema.vcs-url="https://github.com/enonic/xp" \
  org.label-schema.vendor="Enonic" \
  org.label-schema.version="${XP_DISTRO_VERSION}" \
  org.opencontainers.image.created="${build_date}" \
  org.opencontainers.image.authors="Jørgen Sivesind (jsi@enonic.com), Guðmundur Björn Birkisson (gbi@enonic.com)" \
  org.opencontainers.image.documentation="https://developer.enonic.com/" \
  org.opencontainers.image.licenses="GPL-3.0" \
  org.opencontainers.image.source="https://github.com/enonic/xp" \
  org.opencontainers.image.title="Enonic XP" \
  org.opencontainers.image.url="https://enonic.com/platform" \
  org.opencontainers.image.vendor="Enonic" \
  org.opencontainers.image.version="${XP_DISTRO_VERSION}"

RUN \
  # Set environment for all users
  echo "export XP_DISTRO_VERSION=$XP_DISTRO_VERSION" >> /etc/environment && \
  echo "export XP_ROOT=$XP_ROOT" >> /etc/environment && \
  echo "export XP_HOME=$XP_HOME" >> /etc/environment && \
  echo "export XP_USER=$XP_USER" >> /etc/environment && \
  echo "export XP_UID=$XP_UID" >> /etc/environment && \
  # Create user
  adduser --home $XP_ROOT --gecos "" --no-create-home --UID $XP_UID --gid 0 --disabled-password $XP_USER && \
  # UID running the container could be generated dynamically by Openstack.
  # Allow entrypoint to create associated entry in /etc/passwd.
  chmod g=u /etc/passwd && \
  # Install required packages
  DEBIAN_FRONTEND="noninteractive" \
  apt-get -qq update && \
  apt-get -qq upgrade && \
  apt-get -qq install -y \
    dnsutils \
  # Cleanup after apt-get
  && rm -rf /var/lib/apt/lists/*

# Copy in XP and scripts
COPY --from=builder --chown=$XP_UID:0 /tmp/xp $XP_ROOT
COPY --from=builder --chown=$XP_UID:0 /tmp/bin /usr/local/bin

# Set working directory and export ports
WORKDIR $XP_HOME

# Ports
EXPOSE 2609 4848 5701 8080 9200 9300

# Set entrypoint and command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["server.sh"]
