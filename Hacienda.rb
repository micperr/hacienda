# frozen_string_literal: true

class Hacienda
  SETTINGS_FILE = 'Hacienda.yml'
  SYNCED_FOLDERS_LOGFILE = '.synced-folders.log'
  GUEST_HOME_DIR = '/home/vagrant'
  DEFAULT_MPD_MUSIC_DIR = '/vagrant/Music'
  DEFAULT_IP = '10.11.12.13'
  SITETYPES_DIR = 'provision/templates/sites'
  MOUNT_OPTS = %w[rw async nolock sec=sys].freeze
  # MOUNT_OPTS = %w[rw tcp nolock noacl async].freeze
  REQUIRED_SETTINGS = %w[db_password].freeze
  AVAILABLE_SITETYPES = Dir.entries(SITETYPES_DIR)
                           .reject { |f| ['.', '..'].include? f }
                           .map { |s| s.sub('.conf', '') }

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

    folders if is_up_or_reload?
  end

  private

  def vm
    @config.vm.box = 'archlinux/archlinux'
    @config.vm.box_version = '2019.08.05'
    @config.vm.box_check_update = false
    @config.vm.hostname = 'hacienda'
    @config.vm.network 'private_network', ip: @ip
    @config.vm.network 'forwarded_port', guest: 3306, host: 3306
    @config.vm.network 'forwarded_port', guest: 8080, host: 8080
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
    inline('Setting local timezone to Europe/Warsaw', 'timedatectl set-timezone Europe/Warsaw')
    script('Installing system packages', 'packages-sys.sh')
    script('Installing AUR packages', 'packages-aur.sh', false)
    inline('Switching default shell to zsh', 'chsh -s $(which zsh) vagrant')
    inline('Chmod 755 guest workspace ', "chmod 755 #{GUEST_HOME_DIR}")
    script('Configuring MOTD', 'motd.sh')
    script('Configuring PHP', 'php.sh')
    script('Installing MariaDB', 'mariadb.sh', true, [], 'DB_PASSWORD' => @settings['db_password'])
    script('Configuring MPD (Music Player Daemon)', 'mpd.sh', false, [@mpd_music_directory])
    script('Installing prezto', 'prezto.sh', false)
    script('Installing composer', 'composer.sh', false)
    script('Configuring nginx folders', 'nginx.sh')
    script('Configuring nginx predefined sites (phpinfo, adminer)', 'nginx-sites-predefined.sh')
    script('Enabling daemon services', 'daemons.sh')
  end

  private

  def folders
    unless is_up_or_reload?
      error 'Folders setup is designed to run only on `up` and `reload` vagrant\'s actions.'
    end

    hosts = []
    sync_folders = []
    sync_folders_log = (File.exist? SYNCED_FOLDERS_LOGFILE) ? File.readlines(SYNCED_FOLDERS_LOGFILE, chomp: true).map { |l| JSON.parse(l) } : []
    # synced_folders_log = (File.exist? SYNCED_FOLDERS_LOGFILE) ? File.readlines(SYNCED_FOLDERS_LOGFILE, chomp: true).map { |f| JSON.parse(f) } : []

    if @settings.key?('folders') && @settings['folders'].is_a?(Hash)

      @settings['folders'].each do |name, config|
        type = config['type'] ||= error(format('`type` config value is not provided for a "%s" project', name))
        unless AVAILABLE_SITETYPES.include? type
          error("`#{type}` site type is not valid. Valid types are: #{AVAILABLE_SITETYPES.join(', ')}")
        end

        path = config['path'] ||= error(format('`path` config value is not provided for a "%s" project', name))
        domain = (config['domain'] ||= "#{name}.local").downcase
        nginxconf = "/vagrant/#{SITETYPES_DIR}/#{type}.conf"
        has_webpath = (config.include? 'webpath') && !config['webpath'].strip.empty?
        root = has_webpath ? File.join(GUEST_HOME_DIR, name, config['webpath']) : File.join(GUEST_HOME_DIR, name)

        folder_config = Hash[name, config]
        sync_folders.push(folder_config)
        hosts.push(domain)

        # Generate NGINX config files if new or updated
        unless sync_folders_log.include?(folder_config)
          @config.trigger.after :up, :reload do |t|
            t.info = info("Configuring site #{domain}")
            t.run_remote = {
              path: 'provision/nginx-site.sh',
              args: [
                name,       # $1
                nginxconf,  # $2
                root,       # $3
                domain      # $4
              ]
            }
          end
        end

        # Mark folder for VM syncing
        @config.vm.synced_folder path, File.join(GUEST_HOME_DIR, name),
                                 mount_options: MOUNT_OPTS, type: 'nfs' #  nfs_udp: false, nfs_version: 4, "nfs_export": false
      end

    end

    # updated_folders = sync_folders - sync_folders_log
    removed_folders = sync_folders_log.map { |e| e.keys.first } - sync_folders.map { |e| e.keys.first }
    folders_been_removed = !removed_folders.empty?
    folders_been_updated = !(sync_folders - sync_folders_log).empty?

    # Do stuff only only when updates have been detected
    if folders_been_updated || folders_been_removed

      File.open(SYNCED_FOLDERS_LOGFILE, 'w') do |f|
        f.puts(sync_folders.map(&:to_json))
      end

      # Update /etc/hosts on HOST OS
      @config.trigger.after :up, :reload do |t|
        t.info = info('Updating IP-host entries in /etc/hosts')
        t.run = { path: 'provision/hosts.sh', args: [@ip] + hosts }
      end

      # Clean all removed sites
      removed_folders.each do |name|
        @config.trigger.after :reload do |t|
          t.info = info("Cleaning #{name} folder and configs")
          t.run_remote = { path: 'provision/nginx-site-clean.sh', args: [name] }
        end
      end

      # Restart NGINX
      @config.trigger.after :up, :reload do |t|
        t.info = info('Restarting nginx')
        t.run_remote = { inline: 'systemctl restart nginx' }
      end
    end

    # After DESTROY
    @config.trigger.after :destroy do |t|
      t.info = info('Removing IP-host entries from /etc/hosts')
      t.run = { path: 'provision/hosts.sh', args: ['--delete-only'] }
    end

    @config.trigger.after :destroy do |t|
      t.info = info('Removing synced folders log file')
      t.run = { inline: "rm -f #{SYNCED_FOLDERS_LOGFILE}" }
    end
  end

  private

  def is_up_or_reload?
    ARGV.include?('up') || ARGV.include?('reload')
  end

  private

  def is_provisioned?
    File.exist?('.vagrant/machines/default/virtualbox/action_provision')
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
