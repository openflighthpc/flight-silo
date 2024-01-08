# require_relative "./silo"
require "yaml"

class SoftwareMigration
    
  def initialize

    data = YAML.load_file('migrate.yml')
    @enabled_archive = data["enabled_archive"]
    @repositories = data["archives"]

  end

  def switch_archive(archive)
    @enabled_archive = archive;
  end

  def read_archive(archive = @enabled_archive)

    

  end

end