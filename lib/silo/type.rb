require 'yaml'

require_relative 'config'

module FlightSilo
  class Type

    class << self
      def all
        @types ||= [].tap do |a|
          Config.type_paths.each do |p|
            Dir[File.join(p, '*')].each do |d|
              md = YAML.load_file(File.join(d, 'metadata.yml'))
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
        all.values.each(&block)
      end
      
      def exists?(search)
        !!all.find { |t| t.name == search }
      end
    end

    def create(name:, global: false)
      puts "Creating silo #{Paint[self.name, :cyan]}@#{Paint[name, :magenta]}"
      # TODO
    end

    attr_reader :name, :description, :dir

    def initialize(md, dir)
      @name = md[:name]
      @description = md[:description]
      @dir = dir
    end
  end
end
