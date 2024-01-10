require "yaml"

module FlightSilo
  class SoftwareMigration
      
    class << self
      def software_migration
        @software_migration ||= self.new
      end

      def enabled_archive
        software_migration.enabled_archive
      end
      
      def switch_archive(archive)
        software_migration.switch_archive(archive)
      end

      def get_existing_archives
        software_migration.get_existing_archives
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

      def merge(repo_software_items)
        software_migration.merge(repo_software_items)
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

    attr_reader :enabled_archive

    def initialize(file_dir = Config.migration_dir)
      @file_path = File.join(file_dir, 'migration.yml')
      unless File.exist?(@file_path)
        migration_hash = {
          'enabled_archive' => 'default',
          'main_archives' => [],
          'private_archives' => [],
          'items' => []
        }
        `mkdir -p #{file_dir}`
        File.open(@file_path, 'w') do |file|
          file.write(migration_hash.to_yaml)
        end
      end
      data = YAML.load_file(@file_path)
      @main_archives = data["main_archives"]
      @restricted_archives = data["restricted_archives"]
      @enabled_archive = data["enabled_archive"]
      @items = data["items"].select { |item| item['type'] == 'software' }
    end

    def get_existing_archives
      @items
      .map { |item| item['archive'] }
      .push(@enabled_archive)
      .uniq
      .map do |archive|
        main_repo = get_main_repo(archive) || @restricted_archives.include?(archive) ? 2 : 1
        {
          'name' => archive,
          'main_repo' => main_repo
        }
      end
    end

    def switch_archive(archive)
      @enabled_archive = archive
      save
    end

    def get_archive(archive = @enabled_archive)
      archive_items = @items
      .select { |item| item['archive'] == archive }
      .sort_by { |item| [item['name'], item['version']] }
    end

    def get_main_repo(archive = @enabled_archive)
      main_archive = @main_archives.find { |mu| mu['name'] == archive }
      return main_archive['repo_id'] if main_archive
      nil
    end

    def get_repo_migration(repo_id)
      repo_items = @items
      .select { |item| item['repo_id'] = repo_id }
      .sort_by { |item| [item['name'], item['version']] }
      
      {
        'items' => repo_items
      }
    end

    def get_repo_migrations
      {}.tap do |rms|
        @items.each do |item|
          repo_id = item['repo_id']
          rms[repo_id] = get_repo_migration(repo_id) if rms[repo_id].nil?
        end
      end
    end

    def merge(repo_software_items)
      repo_software_items.each do |rsi|
        add(MigrationItem.new(rsi['type'], rsi['name'], rsi['version'], rsi['path'], rsi['absolute'], rsi['repo_id'], rsi['archive']))
      end
      save
    end

    def add(item)
      @items.map! do |i|
        i = item.to_hash if i['name'] == item.name && i['version'] == item.version && i['archive'] == item.archive
        i
      end
      @items << item.to_hash unless @items.any? { |i| i['name'] == item.name && i['version'] == item.version && i['archive'] == item.archive }
      save
    end

    def remove_item(name, version, archive = nil)
      @items.reject! { |item| item['name'] == name && item['version'] == version && (archive.nil? || item['archive'] == archive) }
      save
    end

    def remove_software(name, version, repo_id)
      @items.reject! { |item| item['name'] == name && item['version'] == version && item['repo_id'] == repo_id}
      save
    end

    def remove_repo(repo_id)
      @items.reject! { |item| item['repo_id'] == repo_id}
      save
    end

    def to_hash()
      {
        'enabled_archive' => @enabled_archive,
        'items' => @items
      }
    end

    def save()
      File.open(@file_path, 'w') do |file|
        file.write(to_hash.to_yaml)
      end
    end
  end

  class RepoSoftwareMigration

    class << self
      
      def repo_software_migration(file_path)
        @repo_software_migration ||= self.new(file_path)
      end

      def remove_software(file_path, name, version)
        repo_software_migration(file_path).remove_software(name, version)
      end

    end

    def initialize(file_path)
      @file_path = file_path
      @items = YAML.load_file(file_path)['items']
    end

    def remove_software(name, version)
      @items.reject! { |item| item['name'] == name && item['version'] == version }
      save
    end

    def to_hash()
      {
        'items' => @items
      }
    end
    
    def save()
      File.open(@file_path, 'w') do |file|
        file.write(to_hash.to_yaml)
      end
    end
  
  end

  class MigrationItem

    attr_reader :name, :version, :archive

    def initialize(type, name, version, path, absolute, repo_id, archive = SoftwareMigration.enabled_archive)
      @type = type
      @name = name
      @version = version
      @path = path
      @absolute = absolute
      @repo_id = repo_id
      @archive = archive
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
