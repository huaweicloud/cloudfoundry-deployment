# cloudfoundry-deployment

### Installation

1. pull cloudfoundry-deployment github repository.

```
git clone https://github.com/huaweicloud/cloudfoundry-deployment/
```

2. set cloud credentials.
```

vi keystonerc

  # set your own ENV in the file
  export OS_AUTH_URL="https://iam.eu-west-0.prod-cloud-ocb.orange-business.com/v3"
  export OS_USERNAME=user
  export OS_PASSWORD=password
  export OS_DOMAIN_NAME=domain_name
  export OS_PROJECT_DOMAIN_NAME=project_domain_name
  export OS_USER_DOMAIN_NAME=user_domain_name
  export OS_TENANT_NAME=tenant
  export OS_REGION_NAME=eu-west-0
  export OS_AVAILABILITY_ZONE=eu-west-0b
  export DNS_NAMESERVERS=100.125.0.41
  
```

3. Install cloudfoundry by the following command which can be executed repeatly until success.
```
./install.sh
```

5. If you need to uninsall cloudfoundry, you can run the following command.
```
./uninstall.sh
```
