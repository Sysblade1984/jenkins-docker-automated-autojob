#!/bin/bash

#Translate the Jenkinsfile to job XML using my Python script
sleep 10s

while [[ $(curl -s -w "%{http_code}" http://localhost:8080/login -o /dev/null) != "200" ]]; do
  sleep 5
done

#Set up Jenkins URL
JENKINS_URL="http://localhost:8080"

#Get the access token via Jenkins REST API
ACCESS_TOKEN=$(curl -X POST http://localhost:8080/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken -u $JENKINS_ADMIN_ID:$JENKINS_ADMIN_PASSWORD -s --cookie /var/jenkins_home/custom_scripts/cookies --data 'newTokenName=GlobalToken' | jq -r '.data.tokenValue')

#We receive two tokens, but we really can use the first in the pair
FIRST_ACCESS_TOKEN=$(echo $ACCESS_TOKEN | grep -o '^[^ ]*')

#Invoke job XML constructor for the job from Jenkinsfile
#TODO: Add the actual constructor
python3 /var/tmp/custom_scripts/jenkinsfileToXML.py ${JENKINSFILE_IMPLANTED_GH_REPO}

sleep 3s

echo "Reporting success on XML generation step passage"

#Create a job using Jenkins CLI
java -jar /var/tmp/custom_scripts/jenkins-cli/jenkins-cli.jar -s http://localhost:8080 -auth ${JENKINS_ADMIN_ID}:${ACCESS_TOKEN} create-job automated_job < /var/tmp/custom_scripts/job.xml

#Execute the job (due to Jenkins bug, the GitScm poller does not begin actually polling until a build is done manually at least once)
java -jar /var/tmp/custom_scripts/jenkins-cli/jenkins-cli.jar -s http://localhost:8080 -auth ${JENKINS_ADMIN_ID}:${ACCESS_TOKEN} build automated_job

sleep 40s

kill -9 $(top -b -n 1 | grep java | grep -o -E '[1-9][0-9]*' | head -1)
kill -9 $(top -b -n 1 | grep tini | grep -o -E '[1-9][0-9]*' | head -1)

