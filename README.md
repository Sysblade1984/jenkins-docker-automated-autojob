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
2. Edit Jenkinsfile to contain the clone URL of your repository (with .git) on the line with "git" invokation (**REQUIRED due to a bug JENKINS-41377 in Jenkins, where new build jobs won't auto poll Gitscm**)  - by default it is set to my test repository.
3. Execute the following command (substitute "password" with your preferred Jenkins administrator password, "admin" with the Jenkins admin user name and the URL with your repository address (without .git, but with trailing /, just like in the example below)):
```
JENKINS_ADMIN_ID=admin JENKINS_ADMIN_PASSWORD=password JENKINSFILE_IMPLANTED_GH_REPO=https://github.com/yourUser/yourRepo/ docker-compose up -d
```

## How does it work?

### Security
I use the official Jenkins LTS docker image configured to use Matrix Authorization Strategy with triggeringUsersAuthorizationStrategy policy on builds with Agent-to-Controller Access Control enabled.

### Internal setup process
At the startup, docker image pulls some required applications (python3, jq...), see the list below for more information.

I skip the installation, install plugins using jenkins-plugin-cli and use CasC for the config setup (security, permissions and admin user), then my modified jenkins starter executes the "job patcher" which translates the provided Jenkinsfile to a SCM polling job format (Generic Webhook Trigger plugin). The job is executed once (required due to the bug in Jenkins polling mechanism, see [JENKINS-41377 bug on the bug tracker](https://issues.jenkins.io/browse/JENKINS-41377)) and kill the container, forcing a reboot. 

After it reboots, it's ready to go.

The list of installed plugins can be found in the Dockerfile (the RUN jenkins-plugin-cli command).

Unfortunately, there is no functionality to generate a job *directly from the Jenkinsfile* programmaticaly in Jenkins natively, so the Jenkinsfile in the repo is translated to the Jenkins CLI job file (XML) via python3 script and loaded into Jenkins with Jenkins CLI.

Surprisingly, the Jenkins team also disabled the ability to get CRUMB from a script, making it impossible to fetch API token programmatically with it's current REST API (their documentation suggests to get the token manually instead), so a manual CSRF protection override is done for job injection, and then CSRF protection is re-enabled.

## Storage
Additions to the docker image comprise of:
   * Updating the APT repositories (negligible storage requirements)
   * python3 (around 52MB)
   * jq (for JSON parsing in CLI) (1MB)
   * Payload (around 3.5MB)
   
   Total additions take about 56.5MB of storage, with majority (92.035%) of the space taken by python3.
