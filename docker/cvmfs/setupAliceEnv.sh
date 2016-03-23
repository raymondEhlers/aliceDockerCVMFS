# Run this by sourcing this file!
# ie. . setupAliceEnv.sh

# @info:    Prints check messages
# @args:    success-message
echoInfo ()
{
  printf "\033[1;34m[INFO] \033[0m$1\n"
}

echoInfo "Setting up CVMFS"

# CVMFS setup
sudo cvmfs_config setup
# Only necessary if the setup fails. It can diagnose common issues.
#sudo cvmfs_config chksetup

# Mount CVMFS repos. The list in default.local is not enough
# Mount alice.cern.ch
sudo mkdir -p /cvmfs/alice.cern.ch
sudo mount -t cvmfs alice.cern.ch /cvmfs/alice.cern.ch

# Mount alice-ocdb.cern.ch
sudo mkdir -p /cvmfs/alice-ocdb.cern.ch
sudo mount -t cvmfs alice-ocdb.cern.ch /cvmfs/alice-ocdb.cern.ch

# Setup alice specific cvmfs
source /cvmfs/alice.cern.ch/etc/login.sh

# Now you are ready to select the environment
