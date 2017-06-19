# -*- mode: ruby -*-
# vi: set ft=ruby :

boxes = [ 
  { :hostname => 'rabbit1', :ip_address => '192.168.100.10', :box => 'centos/7', :shell_scripts => ['./scripts/install-docker.sh'], :shell_env => { :REGISTRY_ENDPOINT => 'ci-server:5000'}},
  { :hostname => 'rabbit2', :ip_address => '192.168.100.11', :box => 'centos/7', :shell_scripts => ['./scripts/install-docker.sh'], :shell_env => { :REGISTRY_ENDPOINT => 'ci-server:5000'}},
  { :hostname => 'ci-server', :ip_address => '192.168.100.12', :box => 'centos/7', :shell_scripts => ['./scripts/install-docker.sh'], :shell_env => nil }
]

def create_box(hostname:, cpus: 2, memory: 1024, ip_address:, box: 'centos/7', shell_scripts:, shell_env:)
  Vagrant.configure(2) do |config|
    # vagrant-hostmanager plugin
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true

    config.vm.synced_folder ".", "/vagrant", type: 'rsync',
      rsync__exclude: ".tmp/"

    config.vm.define hostname do |vm_config|
      vm_config.vm.provider :virtualbox do |v|
        v.name = hostname
        v.memory = memory
        v.cpus = cpus
        # add disk configuration
        file_to_disk = "./.tmp/#{hostname}_lvm.vdi"
        controller_name = 'IDE' # 'SATAController'
        unless File.exist?(file_to_disk)
            v.customize ['createhd', '--filename', file_to_disk, '--size', 4096] # size is in MB
            v.customize ['storageattach', :id, '--storagectl', controller_name, '--port', 1, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
        end

      end
      vm_config.vm.box = box
      vm_config.vm.hostname = hostname
      vm_config.vm.network :private_network, ip: ip_address
      vm_config.vm.post_up_message = "Successfully started hostname: #{hostname} ip_address: #{ip_address}"

      shell_scripts.each do |script|
        vm_config.vm.provision :shell do |shell|
          shell.name = "#{script}"
          shell.path = script
          shell.env = shell_env unless shell_env.nil?
        end
      end
    end
  end
end


boxes.each do |box|
    create_box(**box)
end
