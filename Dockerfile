################################################################################
# Build stage 0 `builder`:
################################################################################

ARG build_base_image
FROM $build_base_image as builder

# Set builder environment
ARG build_distro_version
ENV \
  DEBIAN_FRONTEND="noninteractive" \
  DISTRO_VERSION="$build_distro_version" \
  DISTRO_URL="https://repo.enonic.com/public/com/enonic/xp/enonic-xp-generic/$build_distro_version/enonic-xp-generic-$build_distro_version.zip" \
  DISTRO_FOLDER="/tmp/server" \
  BIN_FOLDER="/tmp/bin"

# Get needed build dependencies
RUN \
  apt-get -qq update && \ 
  apt-get -qq install -y wget unzip

# Download and unzip XP to ${DISTRO_FOLDER}
RUN \
  wget -q $DISTRO_URL && \
  unzip -qq enonic-xp-generic-$DISTRO_VERSION.zip && \
  mv $(find . -maxdepth 1 -type d -name 'enonic-xp-generic-*') ${DISTRO_FOLDER}

# Create standard folders so docker will preserve
# folder permissions when mounting named volumes
ENV CREATE_DIRS="config,data,deploy,logs,repo/blob,repo/index,snapshots,work"
RUN bash -c "mkdir -p ${DISTRO_FOLDER}/home/{$CREATE_DIRS}"

# Add jattach to do heap and thread dumps
ENV JATTACH_VERSION=v1.5
RUN \
  mkdir ${BIN_FOLDER} && \
  wget -q https://github.com/apangin/jattach/releases/download/${JATTACH_VERSION}/jattach -O ${BIN_FOLDER}/jattach && \
  chmod +x ${BIN_FOLDER}/jattach

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
# Build stage 1 (the actual XP image):
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
  org.label-schema.url="https://enonic.com/products/enonic-xp" \
  org.label-schema.usage="https://developer.enonic.com/" \
  org.label-schema.vcs-url="https://github.com/enonic/xp" \
  org.label-schema.vendor="Enonic" \
  org.label-schema.version="${XP_DISTRO_VERSION}" \
  org.opencontainers.image.created="${build_date}" \
  org.opencontainers.image.authors="Jørgen Sivesind (jsi@enonic.com), Diego Pasten (dap@enonic.com), Guðmundur Björn Birkisson (gbi@enonic.com)" \
  org.opencontainers.image.documentation="https://developer.enonic.com/" \
  org.opencontainers.image.licenses="GPL-3.0" \
  org.opencontainers.image.source="https://github.com/enonic/xp" \
  org.opencontainers.image.title="Enonic XP" \
  org.opencontainers.image.url="https://enonic.com/products/enonic-xp" \
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
  chmod g=u /etc/passwd

# Copy in XP and scripts
COPY --from=builder --chown=$XP_UID:0 /tmp/server $XP_ROOT
COPY --from=builder --chown=$XP_UID:0 /tmp/bin /usr/local/bin

# Set working directory and export ports
WORKDIR $XP_HOME

# Ports
EXPOSE 2609 4848 8080 9200 9300

# Set entrypoint and command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["server.sh"]
