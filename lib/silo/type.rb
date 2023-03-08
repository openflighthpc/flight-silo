require 'yaml'

require_relative 'config'

module FlightSilo
  class Type

    class << self
      def all
        @types ||= [].tap do |a|
          Config.type_paths.each do |p|
            Dir[File.join(p, '*')].each do |d|
              md = YAML.load_file(File.join(d, 'metadata.yaml'))
              a << Type.new(md, d)
            end
          end
          a.sort_by(&:name)
        end
      end

      def [](search)
        type = all.find{ |t| t.name == search }
        raise UnknownSiloTypeError, "Silo type '#{search}' not found" unless type
        type
      end

      def each(&block)
        all.each(&block)
      end

      def exists?(search)
        !!all.find { |t| t.name == search }
      end
    end

    def create(name:, global: false)
      puts "Creating silo #{Paint[self.name, :cyan]}@#{Paint[name, :magenta]}"
      # TODO
    end

    def state_file
      File.join(@dir, 'state.yaml')
    end

    def state
      return {} unless File.file?(state_file)
      YAML.load_file(state_file) || {}
    end

    def modify_state(&block)
      modified = yield state
      File.open(state_file, 'w') { |f| f.write modified.to_yaml }
    end

    def set_prepared
      modify_state do |s|
        s.tap { |h| h[:prepared] = true }
      end
    end

    def prepared?
      !!state[:prepared]
    end

    attr_reader :name, :description, :dir

    def initialize(md, dir)
      @name = md[:name]
      @description = md[:description]
      @dir = dir
    end
  end
end
