# Run this by sourcing this file!
# ie. . setupAliceEnv.sh
# CVMFS setup
sudo cvmfs_config setup
sudo cvmfs_config chksetup

# Mount alice.cern.ch
sudo mkdir -p /cvmfs/alice.cern.ch
sudo mount -t cvmfs alice.cern.ch /cvmfs/alice.cern.ch

# Setup alice specific cvmfs
source /cvmfs/alice.cern.ch/etc/login.sh

# Now you are ready to select the environment
