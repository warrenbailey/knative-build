CHART_REPO := http://jenkins-x-chartmuseum:8080
NAME := knative-build
OS := $(shell uname)
VERSION := $(shell cat ./VERSION)

init: 
	helm init --client-only

setup: init
	helm repo add jenkins-x-api http://chartmuseum.jenkins-x.io
	helm repo add jenkinsxio http://chartmuseum.jenkins-x.io

build: clean setup
	helm dependency build knative-build
	helm lint knative-build

install: clean build
	helm upgrade ${NAME} knative-build --install

upgrade: clean build
	helm upgrade ${NAME} knative-build --install

delete:
	helm delete --purge ${NAME} knative-build

clean:
	rm -rf knative-build/charts
	rm -rf knative-build/${NAME}*.tgz
	rm -rf knative-build/requirements.lock

release: clean build
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" knative-build/Chart.yaml

else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" knative-build/Chart.yaml
else
	exit -1
endif
	helm package knative-build
	helm package knative-build
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(VERSION).tgz" $(CHART_REPO)/api/charts
	rm -rf ${NAME}*.tgz
