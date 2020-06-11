#!/bin/bash

# this is the path to the repo the build should run from. It should not begin with a leading /.
WILDFLY_REPO="${1:-wildfly}"
WILDFLY_REF="${2:-master}"
WILDFLY_IMAGE_TAG="${3:-latest}"

function help {
cat << EOF
   
Usage: ${0} <github repo> <git ref> <tag to apply to image>

       ${0} wildfly master latest
        - this will deploy from the wildfly/wildfly-s2i repo, using the master 
          branch and tag the image with :latest

Arguments:
        repo:    the git repo to run the deployment in, for example the value 
                 luck3y would indicate the luck3y/wildfly-s2i repo
        git ref: the branch / tag from which the deployment should be created
        tag:     the docker tag to apply to the built image

EOF
}

if [ -z "${WILDFLYS2I_GITHUB_PAT}" ];
then
    echo
    echo "Using this script requires the creation of a personal access token here: https://github.com/settings/tokens"
    echo "The token should have the following permissions: repo:status, repo_deployment, public_repo, read:packages, read:discussion, workflow"
    echo "Then export the token in your current shell: export WILDFLYS2I_GITHUB_PAT=... and re-run this script. Your deployment action will run as the production deploy action in github actions."
    echo
    exit
fi

if [ "${1}" == "--help" ]; then
 help
 exit
fi

if [ -n "${1}" ] && [ $# -lt 3 ]; then
  help
  exit
fi

echo curl \
  -X POST \
  -H "Authorization: token $WILDFLYS2I_GITHUB_PAT" \
  -H "Accept: application/vnd.github.ant-man-preview+json" \
  -H "Content-Type: application/json" \
  https://api.github.com/repos/${WILDFLY_REPO}/wildfly-s2i/deployments \
  --data "{\"ref\": \"${WILDFLY_REF}\", \"required_contexts\": [], \"environment\": \"production\", \"payload\": {\"image_tag\": \"${WILDFLY_IMAGE_TAG}\"}}"
