# The base image is the ALICE slc6 builder image
FROM alisw/slc6-builder
MAINTAINER raymond.ehlers@yale.edu
# Based on https://twiki.cern.ch/twiki/bin/view/Main/DockerCVMFS by ponyisi@utexas.edu 

# Install packages
# Add CVMFS repo
COPY cvmfs/cernvm.repo /etc/yum.repos.d/cernvm.repo
# Update and install packages
RUN yum update -y && yum install -y \
    openssh-server \
    nano \
    vim \
    emacs \
    cvmfs \
    man \
    freetype \
    openssl098e \
    libXpm \
    libXext

# Setup CVMFS settings and permissions
COPY cvmfs/default.local /etc/cvmfs/default.local
# Create cvmfs setup script
COPY cvmfs/setupAliceEnv.sh /root/setupAliceEnv.sh

# Setup gosu. See: https://github.com/tianon/gosu
RUN curl -fsSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64" -o /usr/local/bin/gosu && chmod 0777 /usr/local/bin/gosu

# Copy entryPoint script that uses gosu
COPY dockerConfig/entryPoint.sh /usr/local/bin/entryPoint.sh

# Conveniences for users
# Add git-new-workdir just in case the user wants to try to use the alice-env script
RUN curl -L https://raw.github.com/gerrywastaken/git-new-workdir/master/git-new-workdir -o /usr/bin/git-new-workdir && chmod 0777 /usr/bin/git-new-workdir

# Set the entry point
ENTRYPOINT ["/usr/local/bin/entryPoint.sh"]
