#!/bin/bash

# Install the latest version of Python and PIP.
sudo apt-get install -y python3 python3-pip

# Install Tornado library that is required by the application.
pip3 install tornado

# Run the Python application in the background.
python3 web-server.py &

# Ensure that the web server is accessible.
curl http://localhost:8888

# Build a Docker image with the web server.
sudo docker build -t py-web-server:v1 .

# Run the web server using Docker.
sudo docker run -d -p 8888:8888 --name py-web-server \
	-h my-web-server \
	py-web-server:v1

# List containter running
sudo docker container ls

# Try accessing the web server again, and then stop the container.
curl http://localhost:8888


## Upload the Image to a Registry

# Add the signed in user to the Docker group so 
# you can run docker commands without sudo and push the 
# image to the repository as an authenticated user using the 
# Container Registry credential helper.

sudo usermod -aG docker $USER

# Exit your the SSH session, return to the VM Instances screen in 
# the GCP Console, and launch a new SSH session. This action is 
# needed so that the group change you just made will take effect.

cd /kickstart

# Store your GCP project name in an environment variable.

export GCP_PROJECT=`gcloud config list core/project --format='value(core.project)'`
echo $GCP_PROJECT

# Tag the Docker image that includes the registry name gcr.io

docker tag py-web-server:v1 "gcr.io/${GCP_PROJECT}/py-web-server:v1"

# List Docker images

docker images

# Rebuild the Docker image with a tag that includes the registry name 
# gcr.io and the project ID as a prefix.

# docker build -t "gcr.io/${GCP_PROJECT}/py-web-server:v1" .

## Make the Image Publicly Accessible

# Configure Docker to use gcloud as a Container Registry credential 
# helper (you are only required to do this once).

PATH=/usr/lib/google-cloud-sdk/bin:$PATH
gcloud auth configure-docker

# Push the image to gcr.io.

docker push gcr.io/${GCP_PROJECT}/py-web-server:v1

# To see the image stored as a bucket (object) in your Google Cloud Storage 
# repository, click the Navigation menu icon and select Storage.

# Update the permissions on Google Cloud Storage to make your 
# image repository publicly accessible.

gsutil defacl ch -u AllUsers:R gs://artifacts.${GCP_PROJECT}.appspot.com
gsutil acl ch -r -u AllUsers:R gs://artifacts.${GCP_PROJECT}.appspot.com
gsutil acl ch -u AllUsers:R gs://artifacts.${GCP_PROJECT}.appspot.com

# The Docker image can now be run from any machine that has Docker 
# installed by running the following command.

docker run -d -p 8888:8888 -h my-web-server gcr.io/${GCP_PROJECT}/py-web-server:v1

