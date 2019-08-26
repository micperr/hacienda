# frozen_string_literal: true

class Hacienda
  SETTINGS_FILE = 'Hacienda.yml'
  DEFAULT_IP = '10.11.12.13'
  GUEST_HOME_DIR = '/home/vagrant'
  MOUNT_OPTS = ['dmode=750', 'fmode=640', 'actimeo=1', 'rw', 'tcp', 'nolock', 'noacl', 'async'].freeze
  SITETYPES_DIR = 'provision/templates/sites'
  REQUIRED_SETTINGS = ['host_workspace'].freeze

  def initialize(config)
    @settings = parse_validate_settings
    @config = config
    @ip = @settings['ip'] ||= DEFAULT_IP
  end

  def configure
    vm
    vb
    provision
    copy
    triggers
  end

  private

  def vm
    @config.vm.box = 'archlinux/archlinux'
    @config.vm.hostname = 'hacienda'
    @config.vm.network 'private_network', ip: @ip
    # @config.vm.network 'forwarded_port', guest: 3306, host: 3306
    @config.ssh.forward_agent = true
    self
  end

  private

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

  private

  def provision
    script('Installing systmem packages', 'packages-sys.sh')
    script('Installing AUR packages', 'packages-aur.sh', false)
    inline('Switching shell to zsh', 'chsh -s $(which zsh) vagrant')
    inline('Chmod 755 guest workspace ', "chmod 755 #{GUEST_HOME_DIR}")
    script('Configuring MOTD', 'motd.sh')
    script('Configuring PHP', 'php.sh')
    script('Installing MariaDB', 'mariadb.sh')
    script('Configuring MPD (Music Player Daemon)', 'mpd.sh', false)
    script('Installing prezto', 'prezto.sh', false)
    script('Installing composer', 'composer.sh', false)
    script('Configuring nginx folders', 'nginx-folders.sh')
    inline('Copying nginx.conf', 'cp /vagrant/provision/templates/nginx.conf /etc/nginx/nginx.conf')
    script('Configuring nginx predefined sites (phpinfo, adminer)', 'nginx-sites-predefined.sh')

    # PROJECTS FOLDERS AND SITES
    @hosts = []
    if @settings.include? 'projects'

      avail_sitetypes = Dir.entries(SITETYPES_DIR)
                           .reject { |f| ['.', '..'].include? f }
                           .map { |s| s.sub('.conf', '') }

      @settings['projects'].each do |dir, config|
        type = config['type'] ||= error(format('`type` config value is not provided for a "%s" project', dir))
        domain = (config['domain'] ||= "#{dir}.local").downcase

        unless avail_sitetypes.include? type.to_s
          error("`#{type}` site type is not valid. Valid types are: #{avail_sitetypes.join(', ')}")
        end

        @hosts.push(domain)

        # SYNC FOLDER
        @config.vm.synced_folder File.join(@settings['host_workspace'], dir),
                                 File.join(GUEST_HOME_DIR, dir),
                                 'mount_options' => MOUNT_OPTS,
                                 "type": 'nfs',
                                 "nfs_udp": false,
                                 "nfs_export": false

        # NGINX SITE CONFIG
        root = if (config.include? 'webpath') && !config['webpath'].strip.empty?
                 File.join(GUEST_HOME_DIR, dir, config['webpath'])
               else
                 File.join(GUEST_HOME_DIR, dir)
               end

        site_nginx_block = File.read("#{SITETYPES_DIR}/#{type}.conf").gsub(/{ROOT}|{DOMAIN}/, '{ROOT}' => root, '{DOMAIN}' => domain)
        script("Configuring nginx site #{domain}", 'nginx-site.sh', true, [dir, site_nginx_block])
      end
    end

    self
  end

  private

  def inline(title, command, privileged = true)
    @config.vm.provision 'shell' do |s|
      s.name = info(title)
      s.inline = command
      s.privileged = privileged
    end
  end

  private

  def script(title, script, privileged = true, args = [])
    @config.vm.provision 'shell' do |s|
      s.name = info(title)
      s.path = "provision/#{script}"
      s.privileged = privileged
      s.args = args
    end
  end

  def triggers
    @config.trigger.after :up, :provision, :reload do |t|
      t.info = info('Adding IP-host pairs to /etc/hosts')
      t.run = { path: 'provision/hosts.sh', args: [@ip] + @hosts }
    end
  end

  private

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

  private

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

  private

  def f(path)
    File.join(__dir__, path)
  end

  private

  def error(msg)
    abort "\e[31m#{msg}\e[0m"
  end

  def info(msg)
    "\e[34m#{msg}\e[0m"
  end

  def print_error(msg)
    @config.vm.provision 'shell' do |s|
      s.inline = ">&2 echo \"#{msg}\""
    end
  end
end
