################################################################################
# Build stage 1 `downloader`:
#
# This stage was added because building linux/arm64 images under qemu resulted
# in segmentation faults while downloading artifacts.
################################################################################

ARG build_base_image
FROM alpine AS downloader

# Set downloader environment
ARG build_distro_version
ARG build_distro_path
ENV \
  XP_VERSION="$build_distro_version" \
  XP_DISTRO_PATH=${build_distro_path:-"https://repo.enonic.com/public/com/enonic/xp/enonic-xp-generic/$build_distro_version/enonic-xp-generic-$build_distro_version.tgz"}
WORKDIR /tmp

# Download and unzip XP
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

################################################################################
# Build stage 2 (the actual XP image):
################################################################################

FROM $build_base_image

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

# Install required packages
RUN \
    DEBIAN_FRONTEND="noninteractive" \
      apt-get update && \
      apt-get install -y --no-install-recommends \
          locales \
          jattach \
          curl \
      && apt-get clean && \
      rm -rf /var/lib/apt/lists/* && \
      locale-gen en_US.UTF-8 && \
      update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# Copy in XP and scripts
# Openshift overrides USER and uses ones with randomly uid>1024 and gid=0.
# Allow ENTRYPOINT (and XP) to run even with a different user. So we change
# the group to 0 and give the group same permissions as owner for
# both server files and binaries
COPY --from=downloader /tmp/xp $XP_ROOT
COPY --chown=$XP_UID:0 --chmod=g=u bin/* /usr/local/bin/

RUN \
  # Set environment for all users
  echo "export XP_DISTRO_VERSION=$XP_DISTRO_VERSION" >> /etc/environment && \
  echo "export XP_ROOT=$XP_ROOT" >> /etc/environment && \
  echo "export XP_HOME=$XP_HOME" >> /etc/environment && \
  echo "export XP_USER=$XP_USER" >> /etc/environment && \
  echo "export XP_UID=$XP_UID" >> /etc/environment && \
  # Create user
  useradd --home-dir "$XP_ROOT" --no-create-home --uid "$XP_UID" --gid 0 --shell /usr/sbin/nologin "$XP_USER" && \
  # UID running the container could be generated dynamically by Openstack.
  # Allow entrypoint to create associated entry in /etc/passwd.
  chmod g=u /etc/passwd && \
  # Add the standard bash profile to XP ROOT \
  cp -R /etc/skel/. ${XP_ROOT}/

# Create standard folders so docker will preserve
# folder permissions when mounting named volumes
RUN CREATE_DIRS="config,data,deploy,logs,repo/blob,repo/index,snapshots,work" && \
    for dir in $(echo $CREATE_DIRS | tr ',' ' '); do \
        mkdir --parents ${XP_HOME}/$dir && \
        chown $XP_UID:0 ${XP_HOME}/$dir; \
    done

# Set working directory and export ports
WORKDIR $XP_HOME

# Ports
EXPOSE 2609 4848 5701 8080 9200 9300

# Set entrypoint and command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["server.sh"]
