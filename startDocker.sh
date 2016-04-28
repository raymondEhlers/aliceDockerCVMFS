#!/usr/bin/env bash

# Script exits if the var is unset
set -o nounset
# Script exists if an statement returns a non-zero value
set -o errexit

######
# Functions
######

# Print functions are adapted from docker-machine-nfs
# The substantially increase readability

# @info:    Prints error messages
# @args:    error-message
echoError ()
{
  printf "\033[0;31mFAIL\n\n$1 \033[0m\n"
}

# @info:    Prints warning messages
# @args:    warning-message
echoWarn ()
{
  printf "\033[0;33m$1 \033[0m\n"
}

# @info:    Prints success messages
# @args:    success-message
echoSuccess ()
{
  printf "\033[0;32m$1 \033[0m\n"
}

# @info:    Prints check messages
# @args:    success-message
echoInfo ()
{
  printf "\033[1;34m[INFO] \033[0m$1\n"
}

# @info:    Prints property messages
# @args:    property-message
echoProperties ()
{
  printf "\t\033[0;35m- %s \033[0m\n" "$@"
}

# @info:    Updates the time the script was last run
updateTimeLastRun ()
{
    echo "$(date +%s)" > .startDockerInternal
}

# @info:    Checks for internet connection
# @args:    bool specifying whether this is being used with docker-machine
checkForInternetConnection ()
{
    # Configures the message to display
    dockerMacine="${1:-}"
    if [[ "$dockerMacine" == true ]];
    then
        message=" in docker-machine"
    else
        message=""
    fi

    # Disable exit on error here so that we can handle the error
    set +o errexit

    echoInfo "Checking for internet connection$message. This may take a bit"

    # Check for connectivity
    # If it fails, it will exit because errexit is set.
    if [[ "$dockerMacine" == true ]];
    then
        # Timeouts after 10 seconds so that the user doesn't have to wait forever
        docker-machine ssh "$dockerMachineName" curl --max-time 10 -sSf http://www.google.com > /dev/null
    else
        curl --max-time 10 -sSf http://www.google.com > /dev/null
    fi

    # Displays result
    if [[ "$?" -eq 0 ]];
    then
        echoSuccess "Internet connection available$message!"
    else
        if [[ "$dockerMacine" == true ]];
        then
            echoError "!!! Internet connection does not appear to be available$message! It is needed for CVMFS !!!"
            echoInfo "Restarting docker-machine!"
            docker-machine restart "$dockerMachineName"
        else
            # Does not quit here, as it could be possible to use without a connection
            echoWarn "!!! Internet connection does not appear to be available! It is needed for CVMFS !!!"
        fi
    fi

    # Re-enable exit on error
    set -o errexit
}

##################
# End of functions
##################

# Load user configuration
if [[ ! -e "userConfig.conf" ]];
then
    cp userConfig_stub.conf userConfig.conf
fi
source userConfig.conf

# Entrace to script
echoInfo "Welcome to Docker"
echo #EMPTY

# Note the -None substitution. This ensures that null variables evaluate as such with -z,
# but that it doesn't end execution according to the "nounset" option

# echo in the subshell must be used here because otherwise the array is split and does not print correctly
echoInfo "User input:"
echoProperties "Directories to mount: $(echo ${availableDirs[@]:-None})"
echoProperties "Environmental variables to included: $(echo ${environmentVars[@]:-None})"
echoProperties "Force NFS reconfiguration: $forceNFSReconfiguration"
echo #EMPTY

# Main variables
directoriesToMount=("$HOME")
variablesToSet=()

# Add ALICE_PREFIX as an environmental variable.
# If it is not defined, we guess at the value, since it is fairly standard
variablesToSet+=("ALICE_PREFIX=${ALICE_PREFIX:=$HOME/alicesw}")

# Add user defined variables
# The ":- " inserts a space if the variable is undefined, so nothing is added
variablesToSet+=("${environmentVars[@]:- }")

# Add user defined directories.
# The ":- " inserts a space if the variable is undefined, so nothing is added
for dirName in ${availableDirs[@]:- };
do
    # Check for directories that are inside of others. If found, they are not used
    found=false
    
    # Check against both the user defined dirs and the automatically added dirs (ie "$HOME")
    for comparisonName in ${availableDirs[@]} ${directoriesToMount[@]};
    do
        #echo "$dirName, $comparisonName"
        if [[ "$dirName" == *"$comparisonName"* && "$dirName" != "$comparisonName" ]];
        then
            found=true
            #echo "$dirName is in $comparisonName"
        fi
    done

    # If it is a subfolder, then reject it
    if [[ "$found" == true ]];
    then
        echoWarn "!!! Skipping mount \"$dirName\" since the base folder \"$comparisonName\" is already being mounted !!!"
    else
        if [[ -d "$dirName" ]];
        then
            directoriesToMount+=("$dirName")
        else
            echoWarn "!!! Skipping mount \"$dirName\" since the folder does not seem to exist !!!"
        fi
    fi
done

# Print the final settings that are used with the container
echo #EMPTY
echoInfo "Final Settings:"
echoProperties "Directories to be mounted: $(echo ${directoriesToMount[@]})"
echoProperties "Environmental variables to be included: $(echo ${variablesToSet[@]})"
echoProperties "Force NFS reconfiguration: $forceNFSReconfiguration"

# Check if online - warn if not, since this is required for CVMFS.
checkForInternetConnection

# Handle the OS specific parts
echo #EMPTY
if [[ $(uname -s) == "Darwin" ]];
then
    echoInfo "Running OS X specific functions"
    echo #EMPTY
    # Start docker-machine and setup the env
    if [[ $(docker-machine ls | grep "$dockerMachineName" | awk '{print $4}') != "Running" ]];
    then
        echoInfo "Starting docker machine"
        docker-machine start "$dockerMachineName"
    else
        echoInfo "Docker machine already started"
    fi

    echoInfo "Loading docker environment"
    eval $(docker-machine env "$dockerMachineName")

    checkForInternetConnection true

    # Setup NFS
    echo #EMPTY
    echoInfo "Checking that nfs shares are used. Please follow the instructions of the docker-machine-nfs script"
    nfsArgs=""
    for dirName in ${directoriesToMount[@]};
    do
        nfsArgs="$nfsArgs --shared-folder=$dirName"
    done

    if [[ "$forceNFSReconfiguration" == true ]];
    then
        nfsArgs="$nfsArgs --force"
    fi

    echoInfo "Executing docker-machine-nfs with $nfsArgs"
    docker-machine-nfs "$dockerMachineName" $nfsArgs

    echo #EMPTY
    echoSuccess "The OS X configuration is completed."
else
    echoInfo "Running Linux specific functions"
    # Would share volumes with user namespaces, but it is not compatible with --privileged, which is required
    # to be able to mount CVMFS.

    # Check if the uid and gid match. If not, warn the user.
    # This only matters for Linux since these get remapped by NFS on OS X.
    if [[ $(id -u $USER) -ne $(id -g $USER) ]];
    then
        echo #EMPTY
        echoWarn "!!! User id and group id are not the same! Files saved from the container will not have the same group as on the local system."
    fi

    echo #EMPTY
    echoSuccess "The Linux configuration is completed."
fi

# Check for volume and create if necessary
# This has to be after the OS specific section to ensure that docker-machine has started.
echo #EMPTY
echoInfo "Checking for the CVMFS cache volume"
if [[ -z "$(docker volume ls | grep "$cvmfsCacheName")" ]];
then
    echoInfo "Creating volume for CVMFS cache"
    # Create volume
    docker volume create --name "$cvmfsCacheName"
else
    echoInfo "Found volume \"$cvmfsCacheName\" for CVMFS cache."
fi

# Check for updates every week
if [[ -e ".startDockerInternal" ]];
then
    if [[ $(( $(date +%s) - $(cat .startDockerInternal) )) -ge 604800 ]];
    then
        echo #EMPTY
        echoInfo "Checking for updated image"
        docker pull "$containerImageName"

        # Update the time
        updateTimeLastRun
    fi
else
    updateTimeLastRun
fi

# Setup arguments for docker
arguments=""

# Directories to mount
for dirName in ${directoriesToMount[@]};
do
    arguments="${arguments} -v $dirName:$dirName"
done

# Environmental variables to add
for varName in ${variablesToSet[@]};
do
    arguments="${arguments} -e $varName"
done

# Any additional custom arguments
for argValue in ${additionalArguments:- };
do
    arguments="${arguments} $argValue"
done

# Determine docker run command
if [[ "$forceNFSReconfiguration" == "true" ]]
then
    echoInfo "Check that all directories are accessible. Once confirmed, disable the \"forceNFSReconfiguration\" option!"
fi

echo #EMPTY
echoInfo "docker run arguments:"
echoProperties "\" $arguments  \""

# Start Docker and mount the proper directories
echoInfo "Starting docker run"
# The cmake command is done by hand since the quoting is a pain. It is used via eval $cmakeCommand in the container
# Tell bash to print the command by using debug mode
# See: https://stackoverflow.com/a/9823281
set -x
docker run -it --rm --privileged -v "$cvmfsCacheName":/cvmfsCache ${arguments} -e "LOCAL_USER_ID=$(id -u $USER)" -e "LOCAL_USER_HOME=$HOME" -e cmakeCommand="$cmakeCommand" "$containerImageName" /bin/bash
set +x
