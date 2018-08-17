#!/usr/bin/env bash

# ``install cloudfoundry by bosh``

checkCmdSuccess(){
  $@
  if [ $? -eq 0 ]; then
    echo "Running $@ is success!"
  else
    echo "Running $@ is failed!"
  exit
fi
}

echo "*********************************************************************"
echo "Begin $0"
echo "*********************************************************************"

origin_dir=.cf_in_public_cloud
director_name=bosh-3
bosh_init_tf_dir=bosh-openstack-environment-templates/bosh-init-tf
is_director_exist=true

echo "*******************configure keystonerc file**************************"
. ./keystonerc

echo "*******************waiting for checking if the bosh director is exist ************"
# check if bosh director is exist
bosh -e $director_name env
if [ $? -eq 0 ]; then
  echo "The director exist!"
else
  echo "The director doesn't exist!"
  is_director_exist=false
fi


cd $origin_dir
echo is_director_exist=$is_director_exist
if [[ $is_director_exist = true ]]; then
  checkCmdSuccess echo yes |bosh -e $director_name -d cf delete-deployment --force
fi

# Deleting resources for cf in public cloud
echo "*****************Deleting resources for cf in public cloud************************"
cd bosh-openstack-environment-templates/cf-deployment-tf-simple/


echo "*****************Waiting for the resources to be deleted for cf in public cloud.......************************"
checkCmdSuccess echo yes | ./terraform destroy
echo "*****************The resources has been deleted for cf in public cloud......."


cd ../bosh-init-tf/
if [[ $is_director_exist = true ]]; then
  echo "*****************Waiting for deleting bosh director vm************************"
  bosh_init_dir_tmp_file=bosh_init_dir_tmp.file
  checkCmdSuccess ./terraform show > $bosh_init_dir_tmp_file
  default_key_name=$(grep -o 'default_key_name = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
  external_ip=$(grep -o 'external_ip = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
  internal_ip=$(grep -o 'internal_ip = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
  net_id=$(grep -o '^net_id = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
  internal_cidr=$(grep -o 'internal_cidr = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
  internal_gw=$(grep -o '^internal_gw = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
  
  echo "*****************************Get resources value from output ****************************************"
  echo default_key_name=$default_key_name
  echo external_ip=$external_ip
  echo internal_ip=$internal_ip
  echo net_id=$net_id
  echo internal_cidr=$internal_cidr
  echo internal_gw=$internal_gw
  
  cd ../../
  
  checkCmdSuccess bosh delete-env bosh-deployment/bosh.yml \
  	--state=state.json \
  	--vars-store=creds.yml \
  	-o bosh-deployment/huaweicloud/cpi.yml \
  	-o bosh-deployment/external-ip-with-registry-not-recommended.yml \
  	-o bosh-deployment/jumpbox-user.yml \
  	-v director_name=$director_name \
  	-v internal_cidr=$internal_cidr \
  	-v internal_gw=$internal_gw \
  	-v internal_ip=$internal_ip \
  	-v external_ip=$external_ip \
  	-v auth_url=$OS_AUTH_URL \
  	-v default_key_name=$default_key_name \
  	-v default_security_groups=[bosh] \
  	-v subnet_id=$net_id \
  	-v huaweicloud_password=$OS_PASSWORD \
  	-v huaweicloud_username=$OS_USERNAME \
  	-v huaweicloud_domain=$OS_DOMAIN_NAME \
  	-v huaweicloud_project=$OS_TENANT_NAME \
  	-v private_key=../$bosh_init_tf_dir/bosh.pem \
  	-v az=$OS_AVAILABILITY_ZONE \
  	-v region=$OS_REGION_NAME
  echo "*****************Finished deleting bosh director vm************************"
  cd $bosh_init_tf_dir
fi


echo "*****************Waiting for the resources to be deleted for bosh director in public cloud......."
echo yes | ./terraform destroy
echo "*****************The resources has been deleted for bosh director in public cloud......."
