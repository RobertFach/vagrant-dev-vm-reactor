# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  minion_id = "linux-dev-vm-#{SecureRandom.hex(8)}"
  
  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "hashicorp/precise64"
  config.vm.hostname = "#{minion_id}"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
  #   # Don't boot with headless mode
    vb.gui = true
  #
  #   # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end

$registerScript = <<SCRIPT
   #!/bin/bash
   
   apt-get install -qqy python-software-properties
   add-apt-repository -y ppa:saltstack/salt
   apt-get update
   apt-get install -qqy salt-minion
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
