
The sha1 value of 'bosh-stemcell-3541.10 stemcell<https://github.com/huaweicloud/cloudfoundry-deployment/blob/master/stemcells/bosh-stemcell-3541.10-openstack-kvm-ubuntu-trusty-go_agent.tgz>'_ is : 55b7f938c3affd0f7c94503209a130be1fce1fe6

* Using the following command to genaric the sha1 value of the stemcell

::

    $sha1sum  bosh-stemcell-3541.10-openstack-kvm-ubuntu-trusty-go_agent.tgz
    55b7f938c3affd0f7c94503209a130be1fce1fe6  bosh-stemcell-3541.10-openstack-kvm-ubuntu-trusty-go_agent.tgz

* If the flavor doesn't support kvm, you should use this new stemcell file instead of the original stemcell
  file, before running the   create bosh director command.

  In bosh-deployment/openstack/cpi.yml

::

    - type: replace
      path: /resource_pools/name=vms/stemcell?
      value:
        url: file://bosh-stemcell-3541.10-openstack-kvm-ubuntu-trusty-go_agent.tgz
        sha1: 55b7f938c3affd0f7c94503209a130be1fce1fe6












