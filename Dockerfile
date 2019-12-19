FROM ubuntu:xenial

LABEL maintainer="Jørgen Sivesind (jsi@enonic.com)"
LABEL creator="Diego Pasten (dap@enonic.com)"

USER root

ENV XP_DISTRO_VERSION="7.2.0" \
    XP_ROOT="/enonic-xp" \
    XP_HOME="/enonic-xp/home" \
    XP_USER="enonic-xp" \
    XP_UID="1337"

RUN echo "export XP_DISTRO_VERSION=$XP_DISTRO_VERSION" >> /etc/environment \
  && echo "export XP_ROOT=$XP_ROOT" >> /etc/environment \
  && echo "export XP_HOME=$XP_HOME" >> /etc/environment \
  && echo "export XP_USER=$XP_USER" >> /etc/environment \
  && echo "export XP_UID=$XP_UID" >> /etc/environment \
  && apt-get update -y \
  && apt-get upgrade -y \
  && apt-get install -y wget \
  vim.tiny \
  unzip \
  && apt-get autoremove \
  && apt-get clean \
  && mkdir -p $XP_ROOT \
  && adduser --home $XP_ROOT --gecos "" --no-create-home --UID $XP_UID --disabled-password $XP_USER \
  && chown -R $XP_USER $XP_ROOT


RUN wget -O /tmp/enonic-xp-linux-server-$XP_DISTRO_VERSION.zip https://repo.enonic.com/public/com/enonic/xp/enonic-xp-linux-server/$XP_DISTRO_VERSION/enonic-xp-linux-server-$XP_DISTRO_VERSION.zip \
  && cd /tmp ; unzip enonic-xp-linux-server-$XP_DISTRO_VERSION.zip \
  && mv /tmp/enonic-xp-linux-server-$XP_DISTRO_VERSION/home /tmp/enonic-xp-linux-server-$XP_DISTRO_VERSION/home.org \
  && cp -rf /tmp/enonic-xp-linux-server-$XP_DISTRO_VERSION/* $XP_ROOT/. \
  && rm -rf /tmp/enonic-xp-linux-server-$XP_DISTRO_VERSION.zip \
  && rm -rf /tmp/enonic-xp-linux-server-$XP_DISTRO_VERSION

COPY launcher.sh /launcher.sh
RUN chmod +x /launcher.sh

USER enonic-xp
EXPOSE 8080 5005 5555

CMD /launcher.sh
