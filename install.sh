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


echo "************************** prepare resources *******************************"
minimal_flavor=s3.medium.4
small_flavor=s3.large.2
general_flavor=s3.large.2
small_highmem_flavor=$general_flavor

origin_dir=.cf_in_public_cloud
ext_net_name="admin_external_net"
ext_net_id="0a2228f2-7f8a-45f1-8e09-9039e1d09975"


bosh_init_dir_tmp_file=bosh_init_dir_tmp.file

echo "configure keystonerc file"
. ./keystonerc

if [ ! -d $origin_dir ]; then
  mkdir $origin_dir
fi

cd $origin_dir


if [ ! -d "bosh-openstack-environment-templates" ]; then
  checkCmdSuccess git clone https://github.com/huaweicloud/bosh-openstack-environment-templates
fi
bosh_init_tf_dir=bosh-openstack-environment-templates/bosh-init-tf
cd $bosh_init_tf_dir
cp terraform.tfvars.template terraform.tfvars


sed -i -e "s#\(auth_url = \"\).*#\1${OS_AUTH_URL}\"#" \
-e "s/\(domain_name = \"\).*/\1${OS_DOMAIN_NAME}\"/" \
-e "s/\(user_name = \"\).*/\1${OS_USERNAME}\"/" \
-e "s/\(password = \"\).*/\1${OS_PASSWORD}\"/" \
-e "s/\(tenant_name = \"\).*/\1${OS_TENANT_NAME}\"/" \
-e "s/\(region_name = \"\).*/\1${OS_REGION_NAME}\"/" \
-e "s/\(availability_zone = \"\).*/\1${OS_AVAILABILITY_ZONE}\"/" \
-e "s/\(ext_net_name = \"\).*/\1${ext_net_name}\"/" \
-e "s/\(ext_net_id = \"\).*/\1${ext_net_id}\"/" terraform.tfvars

## 生成bosh.pem秘钥，用于登录后续cf相关的vm机器
if [ -f "bosh.pem" ]
then
  echo "The bosh.pem already exsit."
else
  echo "Started to generate ssh keypair."
  checkCmdSuccess ./generate_ssh_keypair.sh
fi

downloadTerraform(){
  ./terraform init
  if [ $? -eq 0 ]
  then
  	echo "The terraform_0.10.7_linux_amd64 file already exsit."
  else
  	echo "Started to download the terraform package"
  	checkCmdSuccess wget -O terraform_0.10.7_linux_amd64 https://releases.hashicorp.com/terraform/0.10.7/terraform_0.10.7_linux_amd64.zip
    unzip
	if [ ! $? -eq 0 ];then
	  echo yes | apt install zip
	fi
	unzip terraform_0.10.7_linux_amd64
  	echo "SUCCESS: Install terraform"
  fi
}

downloadTerraform

echo "**********************Started to create resource for bosh director in public cloud........**********************"


echo "Waiting for the resources to be created in public cloud......."
echo yes | ./terraform apply > $bosh_init_dir_tmp_file

default_key_name=$(grep -o 'default_key_name = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
external_ip=$(grep -o 'external_ip = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
internal_ip=$(grep -o 'internal_ip = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
net_id=$(grep -o '^net_id = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
router_id=$(grep -o 'router_id = [^,]*' $bosh_init_dir_tmp_file  | grep -o '[A-Za-z0-9-]\+\-[a-zA-Z0-9-]\+')
internal_cidr=$(grep -o 'internal_cidr = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')
subnet_id=$(grep -o 'subnet_id = [^,]*' $bosh_init_dir_tmp_file  | grep -o '[A-Za-z0-9-]\+\-[a-zA-Z0-9-]\+')
internal_gw=$(grep -o '^internal_gw = [^,]*' $bosh_init_dir_tmp_file  |awk '{print $NF}')

echo "*****************************Get resources value from output ****************************************"
echo default_key_name=$default_key_name
echo external_ip=$external_ip
echo internal_ip=$internal_ip
echo net_id=$net_id
echo router_id=$router_id
echo internal_cidr=$internal_cidr
echo subnet_id=$subnet_id
echo internal_gw=$internal_gw
echo "*****************************Finished to create resource for bosh director in public cloud***************"




# Creating resources for cf in public cloud
echo "*************************Creating resources for cf in public cloud************************"
cd ../cf-deployment-tf-simple


cp terraform.tfvars.template terraform.tfvars


zone=\"$OS_AVAILABILITY_ZONE\"
dns_nameservers=\"$DNS_NAMESERVERS\"

sed -i -e "s#\(auth_url = \"\).*#\1${OS_AUTH_URL}\"#" \
-e "s/\(domain_name = \"\).*/\1${OS_DOMAIN_NAME}\"/" \
-e "s/\(user_name = \"\).*/\1${OS_USERNAME}\"/" \
-e "s/\(password = \"\).*/\1${OS_PASSWORD}\"/" \
-e "s/\(project_name = \"\).*/\1${OS_TENANT_NAME}\"/" \
-e "s/\(region_name = \"\).*/\1${OS_REGION_NAME}\"/" \
-e "s#\(availability_zones = \[\).*#\1${zone}\]#" \
-e "s/\(ext_net_name = \"\).*/\1${ext_net_name}\"/" \
-e "s/\(bosh_router_id = \"\).*/\1${router_id}\"/" \
-e "s#^\#\(\).*\(subnet_id = \"\).*#\1\2${subnet_id}\"#" \
-e "s#^\#\(\).*\(internal_cidr = \"\).*#\1\2${internal_cidr}\"#" \
-e "s/\(use_local_blobstore = \"\).*/\1true\"/" \
-e "s/\(use_tcp_router = \"\).*/\1true\"/" \
-e "s/\(num_tcp_ports = \).*/\12/" \
-e "s/\(dns_nameservers = \[\).*/\1${dns_nameservers}\]/" terraform.tfvars

echo "************************Started to create resource for cf in public cloud........************************"
downloadTerraform
echo "************************Waiting for the resources to be created for cf in public cloud************************"
cf_deployment_tf_tmp=cf_deployment_tf_tmp.file 
checkCmdSuccess echo yes | ./terraform apply > $cf_deployment_tf_tmp
cf_network_id=$(grep -o 'network_id = [^,]*' $cf_deployment_tf_tmp  |awk '{print $NF}')
echo "************************Finished to create resource for cf in public cloud****************************************"



############  update libary ##############################################
# checkCmdSuccess apt-get update
checkCmdSuccess echo yes | sudo apt-get install -y build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3

checkCmdSuccess ruby -v

############  install bosh director ##############################################
cd ../../
director_name=bosh-3
bosh_director_ip=$external_ip
export BOSH_ENVIRONMENT=$bosh_director_ip

if [ ! -d "bosh-deployment" ]; then
  checkCmdSuccess git clone https://github.com/huaweicloud/bosh-deployment
fi


# change flavor
sed -i -e "s/\(instance_type: \).*/\1${general_flavor}/" bosh-deployment/huaweicloud/cloud-config.yml
sed -i -e "s/\(instance_type: \).*/\1${general_flavor}/" bosh-deployment/huaweicloud/cpi.yml
if grep -Fq "state_timeout" bosh-deployment/huaweicloud/cpi.yml
then
    "The state_timeout already add in cpi.yml"
else
    sed -i '74a\    state_timeout: 30000' bosh-deployment/huaweicloud/cpi.yml
fi


current_env_ips=$(bosh envs | awk '{print $1}')
echo $current_env_ips

if [[ $current_env_ips =~ $bosh_director_ip ]]
then
	echo "**********************The bosh director already exist!**********************"
else
	echo "**********************Started to create bosh director........**********************"
	rm -rf creds.yml
	checkCmdSuccess bosh create-env bosh-deployment/bosh.yml \
    --state=state.json \
    --vars-store=creds.yml \
    -o bosh-deployment/huaweicloud/cpi.yml \
    -o bosh-deployment/external-ip-with-registry-not-recommended.yml \
	-o bosh-deployment/jumpbox-user.yml \
    -v director_name=$director_name \
    -v internal_cidr=$internal_cidr \
    -v internal_gw=$internal_gw \
    -v internal_ip=$internal_ip \
    -v external_ip=$bosh_director_ip \
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
fi


# Configure local alias
bosh alias-env $director_name -e $bosh_director_ip --ca-cert <(bosh int ./creds.yml --path /director_ssl/ca)
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int ./creds.yml --path /admin_password`

# Log in to the Director
checkCmdSuccess bosh -e $director_name l
echo "**********************Success to login bosh director........**********************"



echo "**********************Started to create cf**********************"
# clone cf-deployment to config and create cloudfoundry
if [ ! -d "cf-deployment" ]; then
  checkCmdSuccess git clone https://github.com/huaweicloud/cf-deployment
fi

# change flavor in cf-deployment
flavor_start_row=$(grep -n "\- name: minimal" cf-deployment/iaas-support/huaweicloud/cloud-config.yml | cut  -d  ":"  -f  1)
sed -i  "$((flavor_start_row+2))s/\(instance_type: \).*/\1${minimal_flavor}/" cf-deployment/iaas-support/huaweicloud/cloud-config.yml
sed -i  "$((flavor_start_row+5))s/\(instance_type: \).*/\1${small_flavor}/" cf-deployment/iaas-support/huaweicloud/cloud-config.yml
sed -i  "$((flavor_start_row+8))s/\(instance_type: \).*/\1${small_highmem_flavor}/" cf-deployment/iaas-support/huaweicloud/cloud-config.yml

preip=$(echo $internal_gw | cut -d '.' -f 1-3)
reserved=\[$preip\.2\-$preip\.50]
sed -i -e "s#\(range: \).*#\1${internal_cidr}#" \
-e "s#\(reserved: \).*#\1${reserved}#" \
-e "s#\(gateway: \).*#\1${internal_gw}#" cf-deployment/iaas-support/huaweicloud/cloud-config.yml

if [ ! -e "bosh-stemcell-1.0-huaweicloud-xen-ubuntu-trusty-go_agent.tgz" ]; then
  wget https://obs-bosh.obs.otc.t-systems.com/bosh-stemcell-1.0-huaweicloud-xen-ubuntu-trusty-go_agent.tgz
  checkCmdSuccess  bosh upload-stemcell bosh-stemcell-1.0-huaweicloud-xen-ubuntu-trusty-go_agent.tgz
fi

checkCmdSuccess echo yes | bosh update-cloud-config \
     -v availability_zone1=\"$OS_AVAILABILITY_ZONE\" \
     -v subnet_id1=\"$net_id\" \
     cf-deployment/iaas-support/huaweicloud/cloud-config.yml

domain_name=example.com

checkCmdSuccess echo yes | bosh -e $director_name -d cf deploy cf-deployment/cf-deployment-simple.yml \
--vars-store cf-vars.yml \
-v system_domain=$domain_name


############  install cf client ##############################################
if [ ! -e "cf-cli_6.33.0_linux_x86-64.tgz" ]; then
  checkCmdSuccess wget -c "https://cli.run.pivotal.io/stable?release=linux64-binary&source=github" -O cf-cli_6.33.0_linux_x86-64.tgz
  tar -xzvf cf-cli_6.33.0_linux_x86-64.tgz -C /usr/local/bin
  checkCmdSuccess cf -v
fi


