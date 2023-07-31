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

    def self.find   # Someday, this will take an argument...
      id = DEFAULT  # ...and this will be removed.
      all.find { |s| s.id == id } || new(id: id, name: id)
    end

    def add_entry(name, version, location)
      @index[name][version] = location
    end

    def filepath
      File.join(Config.snapshots_path, "#{id}.yaml")
    end

    def save
      File.open(filepath, 'w') do |f|
        f.write(to_yaml)
      end
    end

    def to_yaml
      { 'id' => id, 'name' => name, 'index' => index }.to_yaml
    end

    attr_accessor :id, :name, :index

    def initialize(id:, name: nil, index: deep_hash)
      @id = id
      @name = name
      @index = index
    end

    private

    def deep_hash
      Hash.new {|h, k| h[k] = Hash.new(&h.default_proc) }
    end
  end
end
