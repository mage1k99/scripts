#!/bin/bash

# Check if Docker is accessible
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed or accessible. Please install Docker and try again."
    exit 1
fi

# Check if a container named "sonarqube" already exists
if [ $(docker ps -a -f name=sonarqube -q) ]; then
    echo -e "Container with name \e[32msonarqube\e[0m already exists."
    state=$(docker inspect --format '{{.State.Status}}' sonarqube)
    echo -e "The state of the container is \e[31m$state\e[0m."

    read -p "Do you want to use this container? (Y/N): " choice
    choice=${choice:-N}

    if [[ $choice =~ ^[Yy]$ ]]; then
        if [[ $state == 'exited' ]]; then
            docker start sonarqube
            echo "Started the existing sonarqube container."
        else
            echo "The sonarqube container is already running."
        fi
        exit 0
    fi
fi

# Create volumes if they don't exist
volumes=("sonarqube_data" "sonarqube_extensions" "sonarqube_logs" "sonarqube_temp")
mounts=("$PWD/sonarqube/data" "$PWD/sonarqube/extensions" "$PWD/sonarqube/logs" "$PWD/sonarqube/temp")

for i in ${!volumes[@]}; do
    volume=${volumes[$i]}
    if [ $(docker volume ls -q -f name=$volume) ]; then
        echo "Volume $volume already exists."
        read -p "Do you want to use this volume? (Y/N): " choice
        choice=${choice:-N}

        if [[ ! $choice =~ ^[Yy]$ ]]; then
            read -p "Enter a new volume name: " volume
            read -p "Enter a new mount point: " mount
        fi
    else
        docker volume create --name $volume
        echo "Created volume $volume."
    fi
    volumes[$i]=$volume
    mounts[$i]=$mount
done

# Ask for name for sonarqube instance
read -p "Enter a name for the sonarqube instance (default: sonarqube): " name
name=${name:-sonarqube}

# Ask for port to expose sonarqube
while true; do
    read -p "Enter a port to expose sonarqube (default: 9000): " port
    port=${port:-9000}

    # Check if the port is occupied
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        echo "Port $port is already in use. Please enter a different port."
    else
        break
    fi
done

# Run the sonarqube container
docker run \
    -v ${volumes[0]}:${mounts[0]} \
    -v ${volumes[1]}:${mounts[1]} \
    -v ${volumes[2]}:${mounts[2]} \
    -v ${volumes[3]}:${mounts[3]} \
    -d --name $name \
    -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
    -p $port:9000 \
    sonarqube:latest

echo "Sonarqube is now running on port $port."
