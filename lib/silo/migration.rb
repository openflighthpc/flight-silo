require "yaml"

module FlightSilo
  class Migration
      
    class << self
      def migration
        @migration ||= self.new
      end

      def enabled
        migration.enabled
      end

      def enabled_archive
        migration.enabled_archive
      end

      def continue
        migration.continue
      end

      def pause
        migration.pause
      end
      
      def switch_archive(archive)
        migration.switch_archive(archive)
      end

      def public_repos
        migration.public_repos
      end

      def set_main_repo(repo_id, archive = migration.enabled_archive)
        migration.set_main_repo(repo_id, archive)
      end

      def get_main_repo(archive = migration.enabled_archive)
        migration.get_main_repo(archive)
      end

      def get_archive(archive = migration.enabled_archive)
        migration.get_archive(archive)
      end

      def get_repo_migrations
        migration.get_repo_migrations
      end

      def merge(repo_id, repo_software_items)
        migration.merge(repo_id, repo_software_items)
      end

      def add(item, is_public)
        migration.add(item, is_public)
      end

      def remove_item(name, version, archive = nil)
        migration.remove_item(name, version, archive)
      end

      def remove_repo(repo_id)
        migration.remove_repo(repo_id)
      end
    end

    attr_reader :enabled, :enabled_archive, :public_repos

    def initialize(file_dir = Config.migration_dir)
      @file_path = File.join(file_dir, 'migration.yml')
      if File.exist?(@file_path)
        data = YAML.load_file(@file_path)
        @enabled = data["enabled"]
        @enabled_archive = data["enabled_archive"]
        @archives = data["archives"].map do |archive_hash|
          MigrationArchive.construct_by_hash(archive_hash)
        end
      else
        @enabled = true
        @enabled_archive = "".tap do |v|
          8.times{v  << (97 + rand(25)).chr}
        end
        @archives = [].tap do |a|
          a << MigrationArchive.new(@enabled_archive)
        end
        `mkdir -p #{file_dir}`
        save
      end
    end

    def continue
      @enabled = true
      save
    end

    def pause
      @enabled = false
      save
    end

    def get_archive(archive_id = @enabled_archive)
      @archives.select { |archive| archive.id == archive_id}
    end

    def switch_archive(archive_id = nil)
      unless archive_id
        archive_id = "".tap do |v|
            8.times{v  << (97 + rand(25)).chr}
        end
        @archives << MigrationArchive.new(archive_id)
      end
      raise 'Archive does not exist' unless get_archive(archive_id)
      @enabled_archive = archive_id
      save
      archive
    end

    def add(item, archive_id = @enabled_archive)
      get_archive(archive_id).add(item)
    end

    def remove(item, archive = nil)
      @items.reject! { |item| item['name'] == name && item['version'] == version && (archive.nil? || item['archive'] == archive) }
      save
    end

    def remove_repo(repo_id)
      @archives.reject! { |archive| archive.kept_by?(repo_id) }
      save
    end

    def to_hash()
      {
        'enabled' => @enabled,
        'enabled_archive' => @enabled_archive,
        'archives' => @archives.map { |archive| archive.to_hash }
      }
    end

    private

    def save()
      File.open(@file_path, 'w') do |file|
        file.write(to_hash.to_yaml)
      end
    end
  end

  class RepoMigration

    def initialize(file_path, repo_id)
      @file_path = file_path
      if File.exist?(@file_path)
        @archives = data["archives"].map do |archive_repo_hash|
          MigrationArchive.construct_by_repo_hash(archive_repo_hash, repo_id)
        end
      else
        @archives = []
        `mkdir -p #{File.dirname(file_path)}`
        save
      end
    end

    def to_hash()
      {
        'archives' => @archives.map { |archive| archive.to_repo_hash }
      }
    end
    
    private

    def save()
      File.open(@file_path, 'w') do |file|
        file.write(to_hash.to_yaml)
      end
    end
  
  end

  class MigrationArchive
  
    class << self
      def construct_by_hash(archive_hash)
        items = archive_hash['items'].map do |item_hash|
          MigrationItem.construct_by_hash(item_hash)
        end
        MigrationArchive.new(archive_hash['id'], archive_hash['repo_id'], items)
      end

      def construct_by_repo_hash(archive_repo_hash, repo_id)
        archive_hash = archive_repo_hash.merge({
          'repo_id' => repo_id
        })
        construct_by_hash(archive_hash)
      end
    end

    attr_reader :id

    def initialize(id, repo_id = nil, items = [])
      @id = id
      @repo_id = repo_id
      @items = items
    end

    def has?(item)
      @items.any? { |archive_item| archive_item.equals(item) }
    end

    def kept_by?(repo_id)
      @repo_id == repo_id
    end

    def add(item)
      @items.reject! { |archive_item| archive_item.equals(item) }
      @items << item
    end

    def to_hash
      {
        'id' => @id,
        'repo_id' => @repo_id,
        'items' => @items.map { |item| item.to_hash }
      }
    end

    def to_repo_hash
      {
        'id' => @id,
        'items' => @items.map { |item| item.to_hash }
      }
    end
  end

  class MigrationItem

    class << self
      def construct_by_hash(item_hash)
        return SoftwareMigrationItem.new(item_hash['name'], item_hash['version'], item_hash['path'], item_hash['is_absolute'], item_hash['repo_id']) if item_hash['type'] == 'software'
      end
    end

    attr_reader :name, :repo_id

    def initialize(type, name, path, is_absolute, repo_id)
      @type = type
      @name = name
      @path = path
      @is_absolute = is_absolute
      @repo_id = repo_id
    end

    def to_hash
      {
        'type' => @type,
        'name' => @name,
        'path' => @path,
        'is_absolute' => @is_absolute,
        'repo_id' => @repo_id
      }
    end
  end

  class SoftwareMigrationItem < MigrationItem

    attr_reader :version

    def initialize(name, version, path, is_absolute, repo_id)
      super('software', name, path, is_absolute, repo_id)
      @version = version
    end

    def equals(item)
      item['name'] == @name && item['version'] == @version
    end

    def to_hash
      {
        'type' => @type,
        'name' => @name,
        'version' => @version,
        'path' => @path,
        'is_absolute' => @is_absolute,
        'repo_id' => @repo_id
      }
    end
  end
end
