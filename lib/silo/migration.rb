require "yaml"

module FlightSilo
  class SoftwareMigration
      
    class << self
      def software_migration
        @software_migration ||= self.new
      end

      def enabled
        software_migration.enabled
      end

      def enabled_archive
        software_migration.enabled_archive
      end

      def continue
        software_migration.continue
      end

      def pause
        softwar_migration.pause
      end
      
      def switch_archive(archive)
        software_migration.switch_archive(archive)
      end

      def list_all_archives
        software_migration.list_all_archives
      end

      def list_main_archives
        software_migration.list_main_archives
      end

      def list_restricted_archives
        software_migration.list_restricted_archives
      end

      def list_undefined_archives
        software_migration.list_undefined_archives
      end

      def public_repos
        softwar_migration.public_repos
      end

      def set_main_repo(repo_id, archive = software_migration.enabled_archive)
        software_migration.set_main_repo(repo_id, archive)
      end

      def get_main_repo(archive = software_migration.enabled_archive)
        software_migration.get_main_repo(archive)
      end

      def get_archive(archive = software_migration.enabled_archive)
        software_migration.get_archive(archive)
      end

      def get_repo_migrations
        software_migration.get_repo_migrations
      end

      def merge(repo_id, repo_software_items)
        software_migration.merge(repo_id, repo_software_items)
      end

      def add(item)
        software_migration.add(item)
      end

      def remove_item(name, version, archive = nil)
        software_migration.remove_item(name, version, archive)
      end

      def remove_software(name, version, repo_id)
        software_migration.remove_software(name, version, repo_id)
      end

      def remove_repo(repo_id)
        software_migration.remove_repo(repo_id)
      end
    end

    attr_reader :enabled, :enabled_archive, :public_repos

    def initialize(file_dir = Config.migration_dir)
      @file_path = File.join(file_dir, 'migration.yml')
      if File.exist?(@file_path)
        data = YAML.load_file(@file_path)
        @enabled = data["enabled"]
        @enabled_archive = data["enabled_archive"]
        @main_archives = data["main_archives"]
        @restricted_archives = data["restricted_archives"]
        @public_repos = data["public_repos"]
        @items = data["items"].select { |item| item['type'] == 'software' }
      else
        @enabled = true
        @enabled_archive = 'default'
        @main_archives = []
        @restricted_archives = []
        @public_repos = []
        @items = []
        `mkdir -p #{file_dir}`
        save
      end
    end

    def list_all_archives
      @items
      .map { |item| item['archive'] }
      .push(@enabled_archive)
      .uniq
    end

    def list_main_archives
      @main_archives.map { |ma| ma['id'] }
    end

    def list_restricted_archives
      @restricted_archives
    end

    def list_undefined_archives
      list_all_archives - list_main_archives - list_restricted_archives
    end

    def continue
      @enabled = true
      save
    end

    def pause
      @enabled = false
      save
    end

    def switch_archive(archive = nil)
      archive ||= "".tap do |v|
        8.times{v  << (97 + rand(25)).chr}
      end 
      @enabled_archive = archive
      save
      archive
    end

    def get_archive(archive = @enabled_archive)
      archive_items = @items
      .select { |item| item['archive'] == archive }
      .sort_by { |item| [item['name'], item['version']] }
    end

    def set_main_repo(repo_id, archive = @enabled_archive)
      if list_undefined_archives.include?(archive)
        main_archive = {
          'id' => archive,
          'repo_id' => repo_id
        }
        @main_archives << main_archive
        save
      end
    end

    def get_main_repo(archive = @enabled_archive)
      return nil unless list_main_archives.include?(archive)
      main_archive = @main_archives.find { |mu| mu['id'] == archive }
      main_archive['repo_id']
    end

    def get_repo_migrations
      repo_items = @items.group_by { |item| item['repo_id'] }
      public_items = []
      repo_items.each do |repo_id, ris|
        public_items.concat(ris) if @public_repos.include?(repo_id)
      end
      repo_items.delete_if { |repo_id, _ris| @public_repos.include?(repo_id) }
      repo_migrations = {}.tap do |rms|
        repo_items.each do |repo_id, ris|
          rms[repo_id] = {
            'main_archives' => [],
            'restricted_archives' => [],
            'items' => ris
          }
        end
      end

      list_main_archives.each do |ma|
        main_repo_id = get_main_repo(ma)
        archive_restricted_repos = [].tap do |arrs|
          repo_items.each do |repo_id, ris|
            arrs << repo_id if rm['ris'].any? { |ri| ri['archive'] == ma } && repo_id != main_repo_id
          end
        end
        repo_migrations[main_repo_id]['main_archives'] << ma
        archive_restricted_repos.each do |arr|
          repo_migrations[arr]['restricted_archives'] << ma
        end
      end

      list_restricted_archives.each do |ra|
        archive_restricted_repos = [].tap do |arrs|
          repo_items.each do |repo_id, ris|
            arrs << repo_id if rm['ris'].any? { |ri| ri['archive'] == ra }
          end
        end
        archive_restricted_repos.each do |arr|
          repo_migrations[arr]['restricted_archives'] << ra
        end
      end

      undefined_public_items = []
      public_items.each do |pi|
        main_repo_id = get_main_repo(pi['archives'])
        if main_repo_id.nil?
          repo_migrations[main_repo_id]['items'] << pi
        else
          undefined_public_items << pi
        end
      end

      repo_migrations['undefined_items'] = undefined_public_items
      repo_migrations
    end

    def merge(repo_id, repo_software_migration)
      repo_software_migration['main_archives'].each do |ma|
        local_ma = {
          'id' => ma,
          'repo_id' => repo_id
        }
        @main_archives << local_ma
        @restricted_archives.delete(ma)
      end
      repo_software_migration['restricted_archives'].each do |ra|
        @restricted_archives << ra unless list_main_archives.include?(ra) || list_restricted_archives.include?(ra)
      end
      repo_software_migration['items'].each do |rsi|
        add(MigrationItem.new(rsi['type'], rsi['name'], rsi['version'], rsi['path'], rsi['absolute'], rsi['repo_id'], rsi['archive']), rsi['repo_id'] != repo_id)
      end
      save
    end

    def add(item, is_public = false)
      @public_repos.push(item.repo_id).uniq! if is_public
      @items.map! do |i|
        i['name'] == item.name && i['version'] == item.version && i['archive'] == item.archive ? item.to_hash : i
      end
      @items << item.to_hash unless @items.any? { |i| i['name'] == item.name && i['version'] == item.version && i['archive'] == item.archive }
      save
    end

    def remove_item(name, version, archive = nil)
      @items.reject! { |item| item['name'] == name && item['version'] == version && (archive.nil? || item['archive'] == archive) }
      clean_archives
      save
    end

    def remove_software(name, version, repo_id)
      @items.reject! { |item| item['name'] == name && item['version'] == version && item['repo_id'] == repo_id }
      clean_archives
      save
    end

    def remove_repo(repo_id)
      @items.reject! { |item| item['repo_id'] == repo_id}

      # do NOT move this paragraph into clean_archives()
      restrictable_archives = [].tap do |ra|
        list_main_archives.each do |ma|
          @items.reject! { |item| item['archive'] == ma && public_repos.include?(item['repo_id']) }
          ra << ma
        end
      end
      restrictable_archives.each do |ra|
        @main_archives.reject! { |ma| ma['id'] == ra }
        @restricted_archives << ra
      end

      clean_archives
      save
    end

    def to_hash()
      {
        'enabled' => @enabled,
        'enabled_archive' => @enabled_archive,
        'main_archives' => @main_archives,
        'restricted_archives' => @restricted_archives,
        'public_repos' => @public_repos,
        'items' => @items
      }
    end

    private

    def clean_archives()
      # clean the references in main_archives and restricted_archives if the archive no longer exists
      empty_archives = list_all_archives.reject { |archive| archive == @enabled_archive || @items.any? { |item| item['archive'] == archive } }
      @main_archives.reject! { |ma| empty_archives.include?(ma['id']) }
      @restricted_archives -= empty_archives

      # clean the references in public_repos if the repo no longer exists
      @public_repos.reject! { |pr| !@items.any? { |item| item['repo_id'] == pr } }
    end

    def save()
      File.open(@file_path, 'w') do |file|
        file.write(to_hash.to_yaml)
      end
    end
  end

  class RepoSoftwareMigration

    def initialize(file_path)
      @file_path = file_path
      if File.exist?(@file_path)
        data = YAML.load_file(file_path)
        @main_archives = data['main_archives']
        @restricted_archives = data['restricted_archives']
        @items = data['items']
      else
        @main_archives = []
        @restricted_archives = []
        @items = []
        `mkdir -p #{File.dirname(file_path)}`
        save
      end
    end

    def remove_software(name, version)
      @items.reject! { |item| item['name'] == name && item['version'] == version }
      clean_archives
      save
    end

    def to_hash()
      {
        'main_archives' => @main_archives,
        'restricted_archives' => @restricted_archives,
        'items' => @items
      }
    end
    
    private

    def list_all_archives
      @items
      .map { |item| item['archive'] }
      .uniq
    end

    def clean_archives()
      empty_archives = list_all_archives.reject { |archive| @items.any? { |item| item['archive'] == archive } }
      @main_archives -= empty_archives
      @restricted_archives -= empty_archives
    end

    def save()
      File.open(@file_path, 'w') do |file|
        file.write(to_hash.to_yaml)
      end
    end
  
  end

  class MigrationItem

    attr_reader :name, :archive, :repo_id

    def initialize(type, name, path, is_absolute, repo_id, archive = SoftwareMigration.enabled_archive)
      @type = type
      @name = name
      @path = path
      @is_absolute = absolute
      @repo_id = repo_id
      @archive = archive
    end

    def to_hash
      {
        'type' => @type,
        'name' => @name,
        'path' => @path,
        'absolute' => @absolute,
        'repo_id' => @repo_id,
        'archive' => @archive
      }
    end
  end

  class SoftwareMigrationItem < MigrationItem

    attr_reader :version

    def initialize(name, version, path, absolute, repo_id, archive = SoftwareMigration.enabled_archive)
      super('software', name, path, absolute, repo_id, archive)
      @version = version
    end

    def to_hash
      {
        'type' => @type,
        'name' => @name,
        'version' => @version,
        'path' => @path,
        'absolute' => @absolute,
        'repo_id' => @repo_id,
        'archive' => @archive
      }
    end
  end
end
