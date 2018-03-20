#!/bin/bash

DATA_ROOT=$(pwd)/data

GIT_WEB_PORT=9001
GIT_SSH_PORT=9002
JENKINS_PORT=9003
ARTIFACTORY_PORT=9004

JENKINS_ROOT=${DATA_ROOT}/jenkins
GIT_ROOT=${DATA_ROOT}/git
ARTIFACTORY_ROOT=${DATA_ROOT}/artifactory

JENKINS_TAG=jenkins_1
ARTIFACTORY_TAG=artifactory_1
GIT_TAG=git_1

mkdir -p ${JENKINS_ROOT}


#LAUNCH JENKINS
docker pull jenkins/jenkins
docker rm -f ${JENKINS_TAG} 2>/dev/null
docker run -dt \
	--mount type=bind,source="${JENKINS_ROOT}",target=/var/jenkins_home \
	-p ${JENKINS_PORT}:8080 \
	--name ${JENKINS_TAG} jenkins

#LAUNCH ARTIFACTORY
docker pull docker.bintray.io/jfrog/artifactory-oss:latest
docker rm -f ${ARTIFACTORY_TAG} 2>/dev/null
docker run \
	-d -p ${ARTIFACTORY_PORT}:8081 \
	-v ${ARTIFACTORY_ROOT}:/var/opt/jfrog/artifactory \
	--name ${ARTIFACTORY_TAG} docker.bintray.io/jfrog/artifactory-oss
# PAUSE ARTICATORY
docker stop ${ARTIFACTORY_TAG}
	
#LAUNCH GITLAB
docker pull gitlab/gitlab-ce
docker rm -f ${GIT_TAG} 2>/dev/null
docker run \
	-d \
        -p ${GIT_WEB_PORT}:80 \
        -p ${GIT_SSH_PORT}:22 \
	-v ${GIT_ROOT}:/var/opt/jfrog/artifactory \
	--name ${GIT_TAG} gitlab/gitlab-ce


echo "PAUSING"
sleep 300 
echo "BEGIN CONFIGURATION"
# SETUP GIT
docker cp reset_git.sh ${GIT_TAG}:/root
docker exec -it ${GIT_TAG} /bin/bash /root/reset_git.sh

# GET JENKINS_PASSWORD
JENKINS_PWD=`docker exec -it ${JENKINS_TAG} /bin/cat /var/jenkins_home/secrets/initialAdminPassword`

echo "JENKINS: http://localhost:${JENKINS_PORT}"
echo "ARTIFACTORY: http://localhost:${ARTIFACTORY_PORT}"
echo "GIT: (WEB: http://localhost:${GIT_WEB_PORT}) (SSH: http://localhost:${GIT_SSH_PORT})"
echo "JENKINS INITIAL ADMIN PASSWORD: ${JENKINS_PWD}"
