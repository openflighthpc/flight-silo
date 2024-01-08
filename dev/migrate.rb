include "yaml"

class SoftwareMigrationArchive
    
    def initialize(silo, archive_name)
        @archive = YAML.loadfile('migrate.yml')[archive_name]
    end

    def save()
    
        @archive = YAML.loadfile();
    
    end

    def view()

        @
    end
end