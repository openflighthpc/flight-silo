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

  end

  attr_reader :enabled_archive

  def initialize(file_path) # file_path = Config.migration_path
    unless File.exists?(file_path)
      default
    end
    data = YAML.load_file(File.join(file_path, 'migration.yml'))
    @enabled_archive = data["enabled_archive"]
    @items = data["items"]
  end

  def switch_archive(archive)
    @enabled_archive = archive
  end

  def get_archive(archive = @enabled_archive)
    archive_items = @items
    .select { |item| item['archive'] == archive}
    .sort_by { |item| [item['type'], item['name'], item['version']]}
  end

  def merge(repo_software_migration)
    @items.concat(repo_software_migration.items)
  end

end

class RepoSoftwareMigration

  attr_reader :items

  def initialize(repo_id, file_path)
    raise 'file not exists' unless File.exists?(file_path)
    @items = YAML.load_file(path)['items']
    @items.each do |item|
      item['repo_id'] = repo_id
    end
  end

end
