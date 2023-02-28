FROM jenkins/jenkins:lts
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false -Xmx2G
ENV CASC_JENKINS_CONFIG /var/jenkins_home/casc.yaml
RUN jenkins-plugin-cli \
    --plugins \
    ant \
	antisamy-markup-formatter \
	authorize-project \
	build-timeout \
	cloudbees-folder \
	configuration-as-code \
	credentials-binding \
	email-ext \
	git \
	github-branch-source \
	gradle \
	ldap \
	mailer \
	matrix-auth \
	pam-auth \
	pipeline-github-lib \
	pipeline-stage-view \
	ssh-slaves \
	timestamper \
	workflow-aggregator \
	ws-cleanup \
	generic-webhook-trigger
COPY casc.yaml /var/jenkins_home/casc.yaml

USER root
RUN apt-get update
RUN apt-get install python3 -y
RUN apt-get install jq -y

RUN mkdir /var/tmp/custom_scripts/
COPY main.py /var/tmp/custom_scripts/main.py
RUN mkdir /var/tmp/custom_scripts/jenkins-cli
COPY jenkins-cli.jar /var/tmp/custom_scripts/jenkins-cli/jenkins-cli.jar
COPY job_patcher.sh /var/tmp/custom_scripts/job_patcher.sh

COPY Jenkinsfile /var/tmp/custom_scripts/Jenkinsfile
COPY jenkinsfileToXML.py /var/tmp/custom_scripts/jenkinsfileToXML.py
COPY job.xml /var/tmp/custom_scripts/job.xml

RUN chmod 777 /var/tmp/custom_scripts/job_patcher.sh
RUN chmod 777 /var/tmp/custom_scripts/jenkinsfileToXML.py

RUN chmod 701 /var/tmp/custom_scripts/job.xml
RUN chown jenkins:jenkins /var/tmp/custom_scripts/job.xml

COPY jenkins.sh /usr/local/bin/jenkins.sh
RUN chown -R jenkins:jenkins /usr/local/bin/jenkins.sh
RUN chmod 777 /usr/local/bin/jenkins.sh

RUN chown -R jenkins:jenkins /var/tmp/custom_scripts/

USER jenkins

