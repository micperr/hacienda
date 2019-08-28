# frozen_string_literal: true

class Hacienda
  SETTINGS_FILE = 'Hacienda.yml'
  DEFAULT_IP = '10.11.12.13'
  GUEST_HOME_DIR = '/home/vagrant'
  DEFAULT_MPD_MUSIC_DIR = '/vagrant/Music'
  SITETYPES_DIR = 'provision/templates/sites'
  MOUNT_OPTS = ['dmode=750', 'fmode=640', 'actimeo=1', 'rw', 'tcp', 'nolock', 'noacl', 'async'].freeze
  REQUIRED_SETTINGS = %w[host_workspace db_password].freeze

  def initialize(config)
    @settings = parse_and_validate_settings
    @config = config
    @ip = @settings['ip'] ||= DEFAULT_IP
    @mpd_music_directory = @settings['mpd_music_directory'] ||= DEFAULT_MPD_MUSIC_DIR
  end

  def construct
    vm
    provision
    copy
  end

  private

  def vm
    @config.vm.box = 'archlinux/archlinux'
    @config.vm.hostname = 'hacienda'
    @config.vm.network 'private_network', ip: @ip
    @config.vm.network 'forwarded_port', guest: 3306, host: 3306
    @config.vm.network 'forwarded_port', guest: 8000, host: 8000
    @config.ssh.forward_agent = true

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
  end

  private

  def provision
    # script('Installing system packages', 'packages-sys.sh')
    # script('Installing AUR packages', 'packages-aur.sh', false)
    # inline('Switching default shell to zsh', 'chsh -s $(which zsh) vagrant')
    # inline('Chmod 755 guest workspace ', "chmod 755 #{GUEST_HOME_DIR}")
    # script('Configuring MOTD', 'motd.sh')
    # script('Configuring PHP', 'php.sh')
    # script('Installing MariaDB', 'mariadb.sh', true, [], 'DB_PASSWORD' => @settings['db_password'])
    script('Configuring MPD (Music Player Daemon)', 'mpd.sh', false, [@mpd_music_directory])
    # script('Installing prezto', 'prezto.sh', false)
    # script('Installing composer', 'composer.sh', false)
    # script('Configuring nginx folders', 'nginx.sh')
    # script('Configuring nginx predefined sites (phpinfo, adminer)', 'nginx-sites-predefined.sh')

    # setup_projects

    # script('Enabling daemon services', 'daemons.sh')
  end

  private

  # PROJECTS FOLDERS AND SITES
  def setup_projects
    hosts = []
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

        # SYNC FOLDER
        @config.vm.synced_folder File.join(@settings['host_workspace'], dir),
                                 File.join(GUEST_HOME_DIR, dir),
                                 'mount_options' => MOUNT_OPTS,
                                 "type": 'nfs',
                                 "nfs_udp": false
        #  "nfs_export": false

        # NGINX SITE CONFIG
        hasWebpath = (config.include? 'webpath') && !config['webpath'].strip.empty?
        root = hasWebpath ?
                File.join(GUEST_HOME_DIR, dir, config['webpath']) : File.join(GUEST_HOME_DIR, dir)

        script(
          "Configuring nginx site #{domain}", 'nginx-site.sh', true,
          [dir, File.read("#{SITETYPES_DIR}/#{type}.conf").gsub(/{ROOT}|{DOMAIN}/, '{ROOT}' => root, '{DOMAIN}' => domain)]
        )

        hosts.push(domain)
      end

      update_etc_hosts(hosts)

    end

    clean_unused_sites()
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

  def script(title, script, privileged = true, args = [], envs = {})
    @config.vm.provision 'shell' do |s|
      s.name = info(title)
      s.path = "provision/#{script}"
      s.privileged = privileged
      s.args = args
      s.env = envs
    end
  end

  private

  def update_etc_hosts(hosts)
    @config.trigger.after :provision do |t|
      t.info = info('Adding IP-host entries to /etc/hosts')
      t.run = { path: 'provision/hosts.sh', args: [@ip] + hosts }
    end

    @config.trigger.after :destroy do |t|
      t.info = info('Removing IP-host entries from /etc/hosts')
      t.run = { path: 'provision/hosts.sh', args: ['--delete-only'] }
    end
  end

  private

  def clean_unused_sites()
    @config.trigger.after :all do |t|
      t.info = info('Cleaning unused sites folders and configs')
      t.run_remote = { path: 'provision/nginx-sites-clean.sh' }
    end
  end

  private

  def parse_and_validate_settings
    fsettings = f(SETTINGS_FILE)
    unless File.exist? fsettings
      error("Hacienda settings file not found in #{fsettings}. Run `make` command to create it.")
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

  private

  def info(msg)
    "\e[34m#{msg}\e[0m"
  end
end
