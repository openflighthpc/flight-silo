# require_relative "./silo"
require "yaml"

class SoftwareMigration
    
  class << self
    
    def software_migration
      @software_migration ||= self.new
    end

    def get_archive(archive = software_migration.enabled_archive)
      software_migration.get_archive(archive)
    end

    def merge(repo_software_migration)
      software_migration.merge(repo_software_migration)
    end

    def add(item)
      software_migration.add(item)
    end

  end

  attr_reader :enabled_archive

  def initialize(file_dir) # file_path = Config.migration_dir
    @file_path = File.join(file_dir, 'migration.yml')
    unless File.exist?(@file_path)
      migration_hash = {
        'enabled_archive' => 'default',
        'items' => []
      }
      `mkdir -p #{file_dir}`
      File.open(@file_path, 'w') do |file|
        file.write(migration_hash.to_yaml)
      end
    end
    data = YAML.load_file(@file_path)
    @enabled_archive = data["enabled_archive"]
    @items = data["items"]
  end

  def switch_archive(archive)
    @enabled_archive = archive
  end

  def get_archive(archive = @enabled_archive)
    archive_items = @items
    .select { |item| item['archive'] == archive }
    .sort_by { |item| [item['type'], item['name'], item['version']] }
  end

  def get_repo(repo_id)
    repo_items = @items
    .select { |item| item['repo_id'] = repo_id }
    .sort_by { |item| [item['type'], item['name'], item['version']] }
    
    {
      'items': repo_items
    }
  end

  def merge(repo_software_migration)
    @items.concat(repo_software_migration.items)
  end

  def add(item)
    @items << item.to_hash
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

class MigrationItem

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
