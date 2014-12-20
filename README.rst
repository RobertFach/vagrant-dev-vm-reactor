vagrant-dev-vm-reactor
======================

Autonomous Minion Management via Vagrant Shell Provisioners.

This is a reactor formula, which allows a local Vagrant installation/bootstrapped VM to notify Salt Master when a new instance of a vagrant (e.g. developer) vm is created with "vagrant up",  so that it may be automatically bootstrapped amd accepted by the Salt Master. "Vagrant destroy" will result in removing the corresponding minion key on the salt-master for that vm. The security model is a compromise between opening up the master completly, e.g., auto-accepting keys purely or by hostname, and having to define all minion keys beforehand (pre-seeding).
I wanted to achieve the following goals for my salt environment and the managed development environments:
- beeing able to automatically add/remove developer vms
- no preseeding because I don't know the required number of minions and minion-ids beforehand
- preserve some security/access control to the overall system (don't want to open the salt-master completly)
- in principal something similar to chef validator key concept
- limit/restrict the vms to the corresponding part of the top.sls file (restrict access to pillar and states based on hostname)

The goals/requirements are fulfilled by the following reactor. Each developer vm template (Vagrantfile) is considered as a security group. Each group has it's own service key which can be used to accept and delete (with knowledge of hostname) keys of this group. A service key can be only used to accept specific hostname patterns, hence, it is not possible to freely bootstrap nodes by just changing the "minion id" of the developer vm.

Dependencies
------------
- Salt
- salt-api (Install salt-api by following this blog post... http://bencane.com/2014/07/17/integrating-saltstack-with-other-services-via-salt-api/ )
- vagrant (for vagrant part)
- vagrant-triggers plugin (use ``vagrant plugin install vagrant-triggers`` to install plugin)

Master Configuration
--------------------
The following files need to be configured on the Salt master:

- ``/etc/salt/master``
- ``/etc/salt/master.d/salt-api.conf``
- ``/srv/reactor/dev-vm-service.sls``

/etc/salt/master
~~~~~~~~~~~~~~~~
This reactor uses the Salt reactor system. You have to link the reactor system to the corresponding reactor file. Add this to your master config file.

.. code-block:: yaml

    reactor:
      - 'salt/netapi/hook/dev/service':
        - /srv/reactor/dev-vm-service.sls

/etc/salt/master.d/salt-api.conf
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
This reactor makes use of the web hooks system introduced in Salt API 0.8.4. The configuration for Salt API is stored in the salt-api configuration file:

.. code-block:: yaml

    rest_cherrypy:
      port: 9999
      host: 0.0.0.0
      ssl_crt: /etc/ssl/private/cert.pem
      ssl_key: /etc/ssl/private/key.pem
      webhook_disable_auth: True
      webhook_url: /hook

/srv/reactor/dev-vm-service.sls
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
This package includes a file in its ``reactor/`` directory called
``dev-vm-service.sls``. Create the ``/srv/reactor/`` directory on the Salt
Master if it doesn't already exist, and copy this file into it.

/srv/top.sls
~~~~~~~~~~~~
Update your top.sls file to match to the developer vms host group, e.g., by:

.. code-block:: yaml

    base:
     'linux-dev-vm-*':
        - common
        - toolchain
        - developertools

Vagrant Configuration
---------------------
My vagrant configuration is managed in a project specific git repository. The developers can clone that repo to get started. The repository will contain a README and a Vagrantfile which can be used to bootstrap a developer vm for that project.

Vagrantfile
~~~~~~~~~~~
This is the configuration file which is used by vagrant tooling to configure/bootstrap a virtual machine image. I have added the following hooks/parts to connect it with salt stack. I have also included an example Vagrantfile in the repository. In a real world example, you would create and provide your own base box. However, for illustrational purposes, I have used the "hashicorp/precise64" box. Therefore, if you have not yet added the this box, you can do this by issuing the following command

.. code-block:: yaml

    vagrant box add hashicorp/precise32

.. code-block:: yaml

    VAGRANTFILE_API_VERSION = "2"

    Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
       minion_id = "linux-dev-vm-#{SecureRandom.hex(8)}"
       config.vm.box = "hashicorp/precise64"
       config.vm.hostname = "#{minion_id}"

    $registerScript = <<SCRIPT
          #!/bin/bash
          #install salt-minion from PPA
          apt-get install -qqy python-software-properties
          add-apt-repository -y ppa:saltstack/salt
          apt-get update
          apt-get install -qqy salt-minion
          # generate a new minion id + key
          rm -rf /etc/salt/pki
          echo #{minion_id} > /etc/salt/minion_id
          service salt-minion restart
          sleep 5
          curl -s -H 'Accept: application/json' -d id='#{minion_id}' -d key='ac6da72a8caf7795fa5c22e940ccd6b1' -d action='register' -k https://salt-master:9999/hook/dev/service
          sleep 5
    SCRIPT

       config.vm.provision "shell", inline: $registerScript
  
       config.trigger.before :destroy do
         run_remote "curl -s -H 'Accept: application/json' -d id=`hostname` -d key='ac6da72a8caf7795fa5c22e940ccd6b1' -d action='unregister' -k https://salt-master:9999/hook/dev/service"
       end
  
       config.vm.provision :salt do |salt|
	 salt.colorize = true
	 salt.log_level = "info"
	 salt.run_highstate = true
       end
    end

Basic Usage
-----------
Go into the folder which contains your Vagrantfile. Start a new vm by calling:

.. code-block:: bash

    vagrant up

Destroy a vm by calling:

.. code-block:: bash

    vagrant destroy

References
----------
This project on github https://github.com/saltstack-formulas/ec2-autoscale-reactor inspired me in developing this reactor. May thx for the authors for their contribution.
