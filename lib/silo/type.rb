require 'yaml'

require_relative 'config'

module FlightSilo
  class Type

    class << self
      def all
        @types ||= {}.tap do |h|
          tmp = {}.tap do |a|
            Config.type_paths.each do |p|
              Dir[File.join(p, '*')].each do |d|
                md = YAML.load_file(File.join(d, 'metadata.yml'))
                t = Type.new(md, d)
                a[t.name.to_sym] = t if !t.disabled
              end
            end
          end
          tmp.values
             .sort { |a,b| a.name <=> b.name }
             .each { |t| h[t.name.to_sym] = t }
        end
      end

      def [](k)
        all[k.to_sym].tap do |t|
          if t.nil?
            raise UnknownSiloTypeError, "unknown silo type: #{k}"
          end
        end
      end

      def each(&block)
        all.values.each(&block)
      end
    end

    def create(name:, global: false)
      puts "Creating silo #{Paint[self.name, :cyan]}@#{Paint[name, :magenta]}"
      # TODO
    end

    attr_reader :name, :description, :disabled, :dir

    def initialize(md, dir)
      @name = md[:name]
      @description = md[:description]
      @disabled = md[:disabled] || false
      @dir = dir
    end
  end
end
