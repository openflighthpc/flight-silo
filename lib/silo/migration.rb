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

      def archives
        migration.archives
      end

      def continue
        migration.continue
      end

      def pause
        migration.pause
      end
      
      def switch_archive(archive_id)
        migration.switch_archive(archive_id)
      end

      def get_archive(archive = migration.enabled_archive)
        migration.get_archive(archive)
      end

      def add(item, archive_id = migration.enabled_archive)
        migration.add(item, archive_id)
      end
  
      def remove(item, archive_id = migration.enabled_archive)
        migration.remove(item, archive_id)
      end
  
      def remove_all(item)
        migration.remove_all(item)
      end
  
      def add_repo(repoMigration)
        migration.add_repo(repoMigration)
      end
  
      def remove_repo(repo_id)
        migration.remove_repo(repo_id)
      end

      def has_undefined_archive?
        migration.has_undefined_archive?
      end
  
      def define_hosting_repo(repo_id)
        migration.define_hosting_repo(repo_id)
      end

      def to_repo_hashes
        migration.to_repo_hashes
      end
    end

    attr_reader :enabled, :enabled_archive, :archives

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
      @archives.find { |archive| archive.id == archive_id}
    end

    def switch_archive(archive_id = nil)
      raise "Archive \'#{archive_id}\' has already been enabled!" if archive_id == @enabled_archive
      unless archive_id
        archive_id = "".tap do |v|
            8.times{v  << (97 + rand(25)).chr}
        end
        @archives << MigrationArchive.new(archive_id)
      end
      raise 'Archive does not exist' unless get_archive(archive_id)
      old_archive_id = @enabled_archive
      @enabled_archive = archive_id
      if get_archive(old_archive_id).empty?
        remove_archive(old_archive_id)
      end
      save
      archive_id
    end

    def add(item, archive_id = @enabled_archive)
      get_archive(archive_id).add(item)
      save
    end

    # returns hosting repo the archive if it is empty after the item is removed
    def remove(item, archive_id = @enabled_archive)
      archive = get_archive(archive_id)
      archive.remove(item)
      hosting_repo_id = nil
      if archive.empty?
        hosting_repo_id = archive.repo_id unless archive.is_undefined?
        remove_archive(archive.id) unless archive.id == @enabled_archive
      end
      save
      hosting_repo_id
    end

    # remove item from all archives that has a record about it
    # return an array of hosting repo ids of those defined archives that are empty after the item is removed
    def remove_all(item)
      emptied_archive_hosting_repos = []
      local_empty_archive_ids = []
      @archives.each do |archive|
        archive.remove(item)
        if archive.empty?
          emptied_archive_hosting_repos << archive.repo_id unless archive.is_undefined?
          local_empty_archives << archive.id unless archive.id == @enabled_archive
        end
      end

      local_empty_archive_ids.each do |archive_id|
        remove_archive(archive_id)
      end
      save
      emptied_archive_hosting_repos.empty? ? nil : emptied_archive_hosting_repos.uniq
    end

    def remove_archive(archive_id)
      @archives.reject! { |archive| archive.id == archive_id }
      save
    end

    def add_repo(repoMigration)
      @archives.concat(repoMigration.archives)
      save
    end

    def remove_repo(repo_id)
      @archives.reject! { |archive| archive.kept_by?(repo_id) }
      @archives.each do |archive|
        archive.items.reject! { |archive_item| archive_item.repo_id == repo_id }
      end
      switch_archive unless get_archive(@enabled_archive)
      save
    end

    def has_undefined_archive?
      @archives.any? { |archive| archive.is_undefined? }
    end

    def define_hosting_repo(repo_id)
      @archives.each do |archive|
        archive.define(repo_id) if archive.is_undefined?
      end
      save
    end

    def to_hash
      {
        'enabled' => @enabled,
        'enabled_archive' => @enabled_archive,
        'archives' => @archives.map { |archive| archive.to_hash }
      }
    end

    def to_repo_hashes
      {}.tap do |rhs|
        @archives.each do |archive|
          repo_id = archive.repo_id
          rhs[repo_id] = { 'archives' => [] } unless rhs[repo_id]
          rhs[repo_id]['archives'] << archive.to_repo_hash
        end
      end
    end

    private

    def save()
      File.open(@file_path, 'w') do |file|
        file.write(to_hash.to_yaml)
      end
    end
  end

  class RepoMigration

    attr_reader :archives

    def initialize(file_path, repo_id)
      @file_path = file_path
      if File.exist?(@file_path)
        data = YAML.load_file(@file_path)
        @archives = data["archives"].map do |archive_repo_hash|
          MigrationArchive.construct_by_repo_hash(archive_repo_hash, repo_id)
        end
      else
        @archives = []
        `mkdir -p #{File.dirname(file_path)}`
        save
      end
    end

    def to_hash
      {
        'archives' => @archives.map { |archive| archive.to_repo_hash }
      }
    end
    
    private

    def save
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

    attr_reader :id, :repo_id, :items

    def initialize(id, repo_id = nil, items = [])
      @id = id
      @repo_id = repo_id
      @items = items
    end

    def has?(item)
      @items.any? { |archive_item| archive_item.equals(item) }
    end

    def empty?
      @items.empty?
    end

    def kept_by?(repo_id)
      @repo_id == repo_id
    end

    def is_undefined?
      @repo_id.nil?
    end

    def define(repo_id)
      @repo_id = repo_id
    end

    def add(item)
      remove(item)
      @items << item
    end

    def remove(item)
      @items.reject! { |archive_item| archive_item.equals(item) }
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

    attr_reader :name, :path, :is_absolute, :repo_id

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
      item.name == @name && item.version == @version
    end

    def is_software?
      true
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
