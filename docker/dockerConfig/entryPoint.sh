#!/usr/bin/env bash

# From: https://denibertovic.com/posts/handling-permissions-with-docker-volumes/

USER_ID=${LOCAL_USER_ID:-9001}

# Create a new user called "user"
echo "Starting with UID : $USER_ID"
useradd --shell /bin/bash -u $USER_ID -o -c "" -m user

# Setup user
export HOME=/home/user

# Add user to sudo without needing a password
echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Add useful aliases
echo -e "alias lsl=\"ls -lhXF --color=auto\"\nalias lsa=\"lsl -a\"" >> $HOME/.bashrc

# Make the setup script available
cp /root/setupAliceEnv.sh $HOME/setupAliceEnv.sh && chown $(id -u user):$(id -g user) $HOME/setupAliceEnv.sh

# Setup grid certs.
if [[ -d "${LOCAL_USER_HOME:-}/.globus" ]];
then
    mkdir "$HOME/.globus" && chown $(id -u user):$(id -g user) "$HOME/.globus"
    # -h ensures that the permissions are set on the symlink and not on the actual files!
    ln -s "${LOCAL_USER_HOME}/.globus/usercert.pem" "$HOME/.globus/." && chown -h $(id -u user):$(id -g user) "$HOME/.globus/usercert.pem"
    ln -s "${LOCAL_USER_HOME}/.globus/userkey.pem" "$HOME/.globus/." && chown -h $(id -u user):$(id -g user) "$HOME/.globus/userkey.pem"
fi

# Move to the user $HOME directory (technically we move the root user and then open bash in that dir, but it works fine)
cd $HOME

# Launches what was passed to docker run, which is usually "/bin/bash"
exec /usr/local/bin/gosu user "$@"
