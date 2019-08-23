# frozen_string_literal: true

class Hacienda

  SETTINGS_FILE = 'Hacienda.yml'
  REQUIRED_SETTINGS = ['host_workspace']
  DEFAULT_SITETYPE = ['symfony']
  DEFAULT_WEBPATH = ['public']

  def initialize(config)
    @settings = parse_validate_settings()
    @config = config
  end

  def all
    ssh.vm.vb.copy.projects
  end

  def vm
    @config.vm.box = 'archlinux/archlinux'
    @config.vm.hostname = 'hacienda'
    @config.vm.network 'private_network', ip: @settings['ip'] ||= '10.11.12.13'
    @config.vm.network 'forwarded_port', guest: 3306, host: 3306
    @config.vm.synced_folder '.', '/vagrant', disabled: true
    self
  end

  def vb
    @config.vm.provider 'virtualbox' do |vb|
      vb.name = 'ArchLinux Dev Server'
      vb.cpus = @settings['cpus'] ||= 1
      vb.memory = @settings['memory'] ||= 2048
      vb.gui = false
      vb.customize ['modifyvm', :id,
                    '--natdnshostresolver1', 'on',
                    '--natdnsproxy1', 'on',
                    '--ioapic', 'on',
                    '--audio', 'pulse',
                    '--audiocontroller', 'ac97',
                    '--audioout', 'on',
                    '--vram', @settings['vram'] ||= 64,
                    '--ostype', 'ArchLinux_64']
    end
    self
  end

  def ssh
    @config.ssh.forward_agent = true
    self
  end

  def copy
    if @settings.include? 'copy'
      @settings['copy'].each do |file|
        @config.vm.provision 'file' do |f|
          f.source = file['from']
          f.destination = file['to']
        end
      end
    end
    self
  end

  def projects

    if @settings.include? 'projects'

      guest_workspace = @settings['guest_workspace'] ||= '/home/vagrant'
      mount_opts = ['dmode=750','fmode=640','actimeo=1','rw','tcp','nolock','noacl','async']
      # mount_opts = ['actimeo=1', 'nolock']

      @settings['projects'].each do |project|
        name = project['name']
        @config.vm.synced_folder File.join(@settings['host_workspace'], name),
          File.join(guest_workspace, name),
          "mount_options" => mount_opts,
          "type": "nfs",
          "nfs_udp": false,
          "nfs_export": false
      end

    end
  end


  def sites
    if @settings.include? 'projects'

      @settings['projects'].each do |site|
        # domains.push(site['map'])
        type = site['name'] ||= error('Sitre mkdmfdmsdm')
        type = site['type'] ||= DEFAULT_SITETYPE
        webpath = site['webpath'] ||= DEFA
        domain = site['domain'] ||= "#{site['name'].downcase}.local"

        @config.vm.provision 'shell' do |s|
          s.name = 'Creating site: ' + site['name']
          # Convert the site & any options to an array of arguments passed to the
          s.path = script_dir + "/site-types/#{type}.sh"
          s.args = [
            site['name'],  # $1
            site['to'],   # $2
            site['type'], # $3
            site['domain'], # $4
          ]
        end

        config.vm.provision 'shell' do |s|
          s.path = script_dir + "/hosts-add.sh"
          s.args = ['127.0.0.1', site['map']]
        end

    end
  end

  def provision
    @config.vm.provision "shell", path: 'provision/pacman.sh'
    @config.vm.provision "shell", path: 'provision/php.sh'
    @config.vm.provision "shell", path: 'provision/mariadb.sh'
    @config.vm.provision "shell", path: 'provision/prezto.sh', privileged: false
    @config.vm.provision "shell", path: 'provision/composer.sh', privileged: false
    @config.vm.provision "shell", path: 'provision/final.sh'
    @config.vm.provision "shell", path: 'provision/mpd.sh', privileged: false
    @config.vm.provision "shell", path: 'provision/nginx.sh', run: "always"
    self
  end

  def parse_validate_settings
    fsettings = f(SETTINGS_FILE)
    unless File.exist? fsettings
      error("Hacienda settings file not found in #{fsettings}")
    end

    settings = YAML.safe_load(File.read(fsettings))
    missing = REQUIRED_SETTINGS - settings.keys
    missing.each do |key|
      error("`#{key}` must be set in #{fsettings}")
    end

    settings
  end

  def f(path)
    File.join(__dir__, path)
  end

  def error(msg)
    abort "\e[31m#{msg}\e[0m"
  end

  def print_error(msg)
    @config.vm.provision 'shell' do |s|
      s.inline = ">&2 echo \"#{msg}\""
    end
  end
end
