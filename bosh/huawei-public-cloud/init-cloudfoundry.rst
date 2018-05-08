
* Specifying the deployment File

::

     bosh update-cloud-config \
          -v availability_zone1="cn-east-2a" \
          -v availability_zone2="cn-east-2a" \
          -v availability_zone3="cn-east-2a" \
          -v network_id1="your_own_subnet_id_1_in_huawei_public_cloud" \
          -v network_id2="your_own_subnet_id_2_in_huawei_public_cloud" \
          -v network_id3="your_own_subnet_id_3_in_huawei_public_cloud" \
          cf-deployment/iaas-support/openstack/cloud-config.yml

* Deploying Cloud Foundry with haproxy

::

     bosh -e bosh-1 -d cf deploy cf-deployment/cf-deployment.yml \
       --vars-store cf-vars.yml \
       -v system_domain=your_own_domain_name.com \
       -v haproxy_private_ip=your_own_private_ip_in_cloud_config_file  \
       -o cf-deployment/operations/openstack.yml \
       -o cf-deployment/operations/use-haproxy.yml

* Deploying Cloud Foundry with loadbalance

::

     bosh -e bosh-1 -d cf deploy cf-deployment/cf-deployment.yml \
     --vars-store cf-vars.yml \
     -v system_domain=your_own_domain_name.com \
     -o cf-deployment/operations/openstack.yml
