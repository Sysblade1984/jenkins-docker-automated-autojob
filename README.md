# jenkins-docker-automated-autojob
This repository contains a dockerized Jenkins server (based on jenkins/jenkins:lts official docker image) with completely automated setup and automatic job deployment with gitscm polling of a certain GitHub repo.

## Introduction

This repository contains a Jenkins docker image which can be installed and run with a single CLI command.

The installation does the following:
	1) Configures the Jenkins server to use the user provided via the startup command
	2) Secures Jenkins from user registration and sets build and view permission via matrix-auth as follows:
		*) User provided via startup command is administrator
		*) All authenticated users can view jobs
		*) Everyone else can't view anything
	3) Creates a pipeline from the Jenkinsfile in the repository to execute the main.py script (which is also in the repository) on merge of any PR of the GitHub repo provided in the startup command.

## Requirements

You must have the following:
1. A docker installation on the runner machine, and docker-compose
	**NOTE: The machine must be reachable from within GitHub, otherwise Gitscm polling won't work.**
2. GitHub repository with configured webhook.
      An example webhook for a repository with *no permissions*:
      1. Payload URL is set to http://JENKINS_BUILD_USER:JENKINS_BUILD_PASSWORD@YOUR_JENKINS_IP:YOUR_JENKINS_PORT/generic-webhook-trigger/invoke where JENKINS_BUILD_USER and JENKINS_BUILD_PASSWORD is the username-password pair of the user who is authorized to execute builds on the server. **Since this deployment is completely automatic, this user should match the administrator user you'll use during installation!**
      2. Content type: application/json
      3. Secret: leave empty
      
	  I recommend setting the condition of the hook only to allow pull request information.

## How to use? / Installation

First, ensure that you have the requirements from the previous section.
Then, do the following:

### Linux
1. Clone this repository.
2. Edit Jenkinsfile to contain URL of your repository on the "git" invokation (**REQUIRED due to a bug in Jenkins, where new build jobs won't auto poll Gitscm**)  - by default it is set to my test repository.
3. Execute the following command (substitute "password" with your preferred Jenkins administrator password, "admin" with the Jenkins admin user name and the URL with your repository address):
```
JENKINS_ADMIN_ID=admin JENKINS_ADMIN_PASSWORD=password JENKINSFILE_IMPLANTED_GH_REPO=https://github.com/yourUser/yourRepo/ docker-compose up -d
```

## How does it work?

I modified the Jenkins LTS docker image to skip the installation wizard and use CasC for the setup.
The list of installed plugins can be found in the Dockerfile (the RUN jenkins-plugin-cli command).

Also, I modified the original jenkins.sh to execute my own payload in the background at the very start of the script, since there is no documentation on the Dockerfile for the latest jenkins:lts image.

As for the automatic job creation, there is no functionality to generate a job *directly from the Jenkinsfile* programmaticaly in Jenkins natively, so the Jenkinsfile in the repo is translated to the Jenkins CLI job file (XML) via python3 script and loaded into Jenkins with my payload. 

Additions to the docker image comprise of:
   * Updating the APT repositories (negligible storage requirements)
   * python3 (around 52MB)
   * jq (for JSON parsing in CLI) (1MB)
   * Payload (around 3.5MB)
   
   Total additions take about 56.5MB of storage, with majority (92.035%) of the space taken by python3.
