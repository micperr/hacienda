# frozen_string_literal: true

class Hacienda
  SETTINGS_FILE = 'Hacienda.yml'
  REQUIRED_SETTINGS = ['host_workspace'].freeze
  DEFAULT_SITETYPE = 'symfony'

  def initialize(config)
    @settings = parse_validate_settings
    @config = config
  end

  def configure
    vm
    vb
    ssh
    copy
    provision
  end

  private

  def provision
    # @config.vm.provision 'shell', path: 'provision/packages.sh'
    # @config.vm.provision 'shell', inline: 'chsh -s $(which zsh) vagrant'
    # @config.vm.provision 'shell', path: 'provision/motd.sh'
    # @config.vm.provision 'shell', path: 'provision/php.sh'
    # @config.vm.provision 'shell', path: 'provision/mariadb.sh'
    # @config.vm.provision 'shell', path: 'provision/mpd.sh', privileged: false
    # @config.vm.provision 'shell', path: 'provision/prezto.sh', privileged: false
    # @config.vm.provision 'shell', path: 'provision/composer.sh', privileged: false

    @config.vm.provision 'shell', path: 'provision/nginx.sh'
    # @config.vm.provision 'file', source: './provision/templates/nginx.conf', destination: '/etc/nginx/nginx.conf'
    # @config.vm.provision 'shell', path: 'provision/nginx-sites-predefined.sh'

    if @settings.include? 'projects'

      sitetypes_path = 'provision/templates/sites'
      guest_workspace = @settings['guest_workspace'] ||= '/home/vagrant'
      avail_sitetypes = Dir.entries(sitetypes_path).reject { |f| ['.', '..'].include? f }
      mount_opts = ['dmode=750', 'fmode=640', 'actimeo=1', 'rw', 'tcp', 'nolock', 'noacl', 'async']
      # mount_opts = ['actimeo=1', 'nolock']

      @settings['projects'].each do |proj|

        name = proj['name'] ||= error("`name` must be provided for a project #{proj}")
        type = proj['type'] ||= DEFAULT_SITETYPE
        domain = proj['domain'] ||= "#{name}.local"

        unless avail_sitetypes.include? "#{type}.conf"
          error("`#{type}` site type is not valid")
        end

        #########
        # SYNCED FOLDERS
        #
        # @config.vm.synced_folder File.join(@settings['host_workspace'], name),
        #                          File.join(guest_workspace, name),
        #                          'mount_options' => mount_opts,
        #                          "type": 'nfs',
        #                          "nfs_udp": false,
        #                          "nfs_export": false

        #########
        # SITES
        #
        # webpath = proj['webpath'] ||= DEFAULT_WEBPATH

        if (proj.include? 'webpath') && ! proj['webpath'].strip.empty?
          root = "#{guest_workspace}/#{name}/#{proj['webpath']}"
        else
          root = "#{guest_workspace}/#{name}"
        end

        block = File.read("#{sitetypes_path}/#{type}.conf").gsub(/{ROOT}|{DOMAIN}/, '{ROOT}' => root, '{DOMAIN}' => domain.downcase)

        @config.vm.provision "shell", inline: <<-SITE
          echo "#{block}" > /etc/nginx/sites-available/#{name}.conf
          ln -s /etc/nginx/sites-available/#{name}.conf /etc/nginx/sites-enabled/#{name}.conf
SITE

        # @config.vm.provision 'shell' do |s|
        #   s.name = 'Creating site: ' + name
        #   s.path = '/provision/site.sh'
        #   s.args = [
        #     name,  # $1
        #     block,  # $2
        #     # domain # $3
        #     # root  # $4
        #   ]
        # end

        # config.vm.provision 'shell' do |s|
        # s.path = script_dir + '/hosts-add.sh'
        # s.args = ['127.0.0.1', site['map']]
        # end
      end
    end

    self
  end

  private

  def vm
    @config.vm.box = 'archlinux/archlinux'
    @config.vm.hostname = 'hacienda'
    @config.vm.network 'private_network', ip: @settings['ip'] ||= '10.11.12.13'
    # @config.vm.network 'forwarded_port', guest: 3306, host: 3306
    @config.vm.synced_folder '.', '/vagrant', disabled: true
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

  def ssh
    @config.ssh.forward_agent = true
    self
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

  def print_error(msg)
    @config.vm.provision 'shell' do |s|
      s.inline = ">&2 echo \"#{msg}\""
    end
  end
end
