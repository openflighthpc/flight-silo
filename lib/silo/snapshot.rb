module FlightSilo
  class Snapshot
    DEFAULT = 'default'

    def self.all
      @all ||= [].tap do |a|
        Dir[File.join(Config.snapshots_path, '*.yaml')].sort.each do |f|
          md = YAML.load_file(f)
          a << new(
            id: File.basename(f, '.yaml'),
            name: md['name'],
            index: md['index']
          )
        end
      end
    end

    def self.find(id)
      all.find { |s| s.id == id }
    end

    def filepath
      File.join(Config.snapshots_dir, "#{id}.yaml")
    end

    def save
      File.open(filepath, 'w') do |f|
        f.write(to_yaml)
      end
    end

    def to_yaml
      { 'id' => id, 'name' => name, 'index' => index }.to_yaml
    end

    def initialize(id:, name: nil, index: nil)
      @id = id
      @name = name
      @index = index
    end
  end
end
