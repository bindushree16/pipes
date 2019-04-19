#!/bin/bash -e

set_context() {
  echo "CURR_JOB=$JOB_NAME"
  echo "DEPLOY_VERSION=$DEPLOY_VERSION"

  echo "BASTION_USER=$BASTION_USER"
  echo "BASTION_IP=$BASTION_IP"
  echo "ONEBOX_USER=$ONEBOX_USER"
  echo "ONEBOX_IP=$ONEBOX_IP"
}

configure_node_creds() {
  echo "Extracting AWS PEM"
  echo "-----------------------------------"
  pushd $(shipctl get_resource_meta "$RES_PEM")
  if [ ! -f "integration.json" ]; then
    echo "No credentials file found at location: $RES_PEM"
    return 1
  fi

  cat integration.json | jq -r '.key' > key.pem
  chmod 600 key.pem

  echo "Completed Extracting AWS PEM"
  echo "-----------------------------------"

  ssh-add key.pem
  echo "SSH key added successfully"
  echo "--------------------------------------"
  popd
}

pull_ribbit_repo() {
  echo "Pull admiral-repo started"
  local PULL_CMD="git -C /home/ubuntu/ribbit pull origin master"
  ssh -A $BASTION_USER@$BASTION_IP ssh $SWARM_USER@$SWARM_IP "$PULL_CMD"
  echo "Successfully pulled admiral-repo"
}

pull_images() {
  echo "Pulling images to deplor for $DEPLOY_VERSION to OneBox"
  echo "AWS login has occurred, will need to change once we move to artifactory"
  echo "--------------------------------------"

  echo "SSH key file list"
  ssh-add -L

  local pull_command="sudo docker pull $KRIBBIT_IMG:$DEPLOY_VERSION"
  echo "--------------------------------------"
  echo "Executing inspect command: $pull_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$pull_command"
  echo "-------------------------------------"

  local pull_command="sudo docker pull $KWWW_IMG:$DEPLOY_VERSION"
  echo "--------------------------------------"
  echo "Executing inspect command: $pull_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$pull_command"
  echo "-------------------------------------"

  local pull_command="sudo docker pull $KAPI_IMG:$DEPLOY_VERSION"
  echo "--------------------------------------"
  echo "Executing inspect command: $pull_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$pull_command"
  echo "-------------------------------------"

  local pull_command="sudo docker pull $KMICRO_IMG:$DEPLOY_VERSION"
  echo "--------------------------------------"
  echo "Executing inspect command: $pull_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$pull_command"
  echo "-------------------------------------"
}

deploy() {
  echo "Deploying the release $DEPLOY_VERSION to OneBox"
  echo "--------------------------------------"

  echo "SSH key file list"
  ssh-add -L

  local inspect_command="ip addr"
  echo "Executing inspect command: $inspect_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$inspect_command"
  echo "-------------------------------------="

#  local deploy_command="sudo /home/ubuntu/ribbit/ribbit.sh upgrade"
#  echo "Executing deploy command: $deploy_command"
#  ssh -A $BASTION_USER@$BASTION_IP ssh $ONEBOX_USER@$ONEBOX_IP "$deploy_command"
#  echo "-------------------------------------="

  echo "Successfully deployed release $DEPLOY_VERSION to Onebox env"
}

create_version() {
  echo "Creating a state file for" $CURR_JOB
  # create a state file so that next job can pick it up
  echo "versionName=$DEPLOY_VERSION" > "$JOB_STATE/$CURR_JOB.env" #adding version state
  echo "Completed creating a state file for" $CURR_JOB
}

main() {
  eval $(ssh-agent -s)
  set_context
  configure_node_creds
#  pull_ribbit_repo
  pull_images
  deploy
#  create_version
}

main