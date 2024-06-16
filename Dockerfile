############## build stage ##############
FROM golang:1.14-buster AS easy-novnc-build

WORKDIR /src

RUN \
 go mod init build && \
 go get github.com/geek1011/easy-novnc@v1.1.0 && \
 go build -o /bin/easy-novnc github.com/geek1011/easy-novnc

############## runtime stage ##############
FROM ubuntu:jammy

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

RUN \
 # create user
 useradd -u 1000 -U -m -s /bin/false obs && \
 usermod -G users obs && \

 # Install packages
 apt-get update -y && \
 apt-get upgrade -y && \
 apt-get install -y \
  software-properties-common && \
    
 add-apt-repository "ppa:obsproject/obs-studio" && \   
 apt-get update -y && \
 apt-get install -y --no-install-recommends \
  # Misc
  openbox \
  supervisor \
  gosu \
    
  # Tools
  lxterminal \
  nano \
  wget \
  htop \
  tar \
  xzip \
  gzip \
  bzip2 \
  zip \
  unzip \   
  net-tools \
  vainfo \
    
  # VNC
  tigervnc-standalone-server \
  tigervnc-tools \
  tigervnc-xorg-extension \
        
  # Drivers
  intel-media-va-driver-non-free \
    
  # Encoder/Decoder    
  ffmpeg \
  vlc \
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
    
  # OBS
  obs-studio && \
 
 # clean   
 apt-get autoclean && \
 apt-get autoremove -y && \
 rm -rf /var/lib/apt/lists/* && \
 
 # add gstreamer plugin
 wget -P /tmp 'https://github.com/fzwoch/obs-gstreamer/releases/download/v0.4.0/obs-gstreamer.zip' && \
 unzip -d /tmp/obs-gstreamer /tmp/obs-gstreamer.zip && \
 cp /tmp/obs-gstreamer/linux/obs-gstreamer.so /usr/lib/x86_64-linux-gnu/obs-plugins/ && \
 rm -r /tmp/obs-gstreamer* 

# add local files
COPY --from=easy-novnc-build /bin/easy-novnc /usr/local/bin/
COPY root/ /

# set permission
RUN \
 chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 5900 8080
WORKDIR /config
VOLUME /config
