############## build stage ##############
FROM golang:1.26.5-bookworm AS easy-novnc-build

WORKDIR /src

RUN \
    go mod init build && \
    go get github.com/geek1011/easy-novnc@v1.1.0 && \
    go build -o /bin/easy-novnc github.com/geek1011/easy-novnc


############## runtime stage ##############
FROM ubuntu:26.04

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

# plugin versions
ARG OBS_GSTREAMER_VERSION="0.4.1"
ARG OBS_IRL_SOURCE_VERSION="1.4.1"


# create user
RUN \
    userdel -r ubuntu 2>/dev/null || true; \
    groupdel ubuntu 2>/dev/null || true; \
    useradd -u 1000 -U -m -s /bin/false obs; \
    usermod -G users obs


# install repository requirements
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        software-properties-common && \
    add-apt-repository -y "ppa:obsproject/obs-studio" && \
    rm -rf /var/lib/apt/lists/*


# install packages
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        \
        # Misc
        openbox \
        supervisor \
        gosu \
        \
        # Tools
        lxterminal \
        nano \
        wget \
        htop \
        tar \
        xz-utils \
        gzip \
        bzip2 \
        zip \
        unzip \
        net-tools \
        vainfo \
        \
        # VNC
        tigervnc-standalone-server \
        tigervnc-tools \
        tigervnc-xorg-extension \
        \
        # Drivers
        intel-media-va-driver-non-free \
        \
        # Encoder / Decoder
        ffmpeg \
        vlc \
        \
        # GStreamer
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav \
        gstreamer1.0-tools \
        gstreamer1.0-x \
        gstreamer1.0-alsa \
        gstreamer1.0-gl \
        gstreamer1.0-gtk3 \
        gstreamer1.0-qt5 \
        gstreamer1.0-pulseaudio \
        \
        # OBS
        qt6-svg-plugins \
        obs-studio && \
    \
    # clean apt cache
    rm -rf /var/lib/apt/lists/*


# add obs-gstreamer plugin
RUN \
    wget \
        -O /tmp/obs-gstreamer.zip \
        "https://github.com/fzwoch/obs-gstreamer/releases/download/v${OBS_GSTREAMER_VERSION}/obs-gstreamer.zip" && \
    \
    mkdir -p /tmp/obs-gstreamer && \
    unzip \
        /tmp/obs-gstreamer.zip \
        -d /tmp/obs-gstreamer && \
    \
    install -Dm755 \
        /tmp/obs-gstreamer/linux/obs-gstreamer.so \
        /usr/lib/x86_64-linux-gnu/obs-plugins/obs-gstreamer.so && \
    \
    rm -rf \
        /tmp/obs-gstreamer \
        /tmp/obs-gstreamer.zip


# add obs-irl-source plugin
RUN \
    wget \
        -O /tmp/obs-irl-source.tar.gz \
        "https://github.com/irlserver/obs-irl-source/releases/download/v${OBS_IRL_SOURCE_VERSION}/obs-irl-source-${OBS_IRL_SOURCE_VERSION}-linux-x64.tar.gz" && \
    \
    mkdir -p /tmp/obs-irl-source && \
    tar \
        -xzf /tmp/obs-irl-source.tar.gz \
        -C /tmp/obs-irl-source && \
    \
    # plugin binary
    install -Dm755 \
        /tmp/obs-irl-source/obs-irl-source/bin/64bit/obs-irl-source.so \
        /usr/lib/x86_64-linux-gnu/obs-plugins/obs-irl-source.so && \
    \
    # plugin data / locale / licenses
    mkdir -p \
        /usr/share/obs/obs-plugins/obs-irl-source && \
    cp -a \
        /tmp/obs-irl-source/obs-irl-source/data/. \
        /usr/share/obs/obs-plugins/obs-irl-source/ && \
    \
    rm -rf \
        /tmp/obs-irl-source \
        /tmp/obs-irl-source.tar.gz


# add local files
COPY --from=easy-novnc-build /bin/easy-novnc /usr/local/bin/
COPY root/ /


# set permissions
RUN \
    chmod +x /entrypoint.sh


ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 5900 8080

WORKDIR /config

VOLUME /config
