#!/bin/bash

# set VNC password
if [ -n "$VNC_PASSWORD" ]; then
  echo "$VNC_PASSWORD" | tigervncpasswd -f > /.vncpasswd
  chown obs:obs/.vncpasswd && chmod 400 /.vncpasswd
  sed -i 's/^command=\/usr\/bin\/Xtigervnc.*/& -rfbauth \/.vncpasswd/' /etc/supervisord.conf
  export VNC_PASSWORD=
fi

# change UID/GID
PUID=${PUID:-1000}
PGID=${PGID:-1000}

groupmod -o -g "$PGID" obs
usermod -o -u "$PUID" obs

# GID video
# Modified from: https://github.com/linuxserver/docker-tvheadend/blob/master/root/etc/cont-init.d/50-gid-video
FILES=$(find /dev/dri -type c -print 2>/dev/null)

for i in $FILES
do
  VIDEO_GID=$(stat -c '%g' "$i")
  if id -G obs | grep -qw "$VIDEO_GID"; then
    touch /groupadd
  else
    if [ ! "${VIDEO_GID}" == '0' ]; then
      VIDEO_NAME=$(getent group "${VIDEO_GID}" | awk -F: '{print $1}')
      if [ -z "${VIDEO_NAME}" ]; then
        VIDEO_NAME="video$(head /dev/urandom | tr -dc 'a-z0-9' | head -c8)"
        groupadd "$VIDEO_NAME"
        groupmod -g "$VIDEO_GID" "$VIDEO_NAME"
      fi
      usermod -a -G "$VIDEO_NAME" obs
      touch /groupadd
    fi
  fi
done
if [ -n "${FILES}" ] && [ ! -f "/groupadd" ]; then
  usermod -a -G root obs
fi

# create directories
if [ ! -d "/home/obs/.config" ]; then
  mkdir -p /home/obs/.config
fi

if [ ! -d "/config" ]; then
  mkdir -p /config
fi

if [ ! -d "/home/obs/.config/obs-studio" ]; then
  ln -s /config /home/obs/.config/obs-studio
fi

# Set permissions
chown obs:obs -R /home/obs
chown obs:obs /dev/stdout

# Run
exec gosu obs supervisord
