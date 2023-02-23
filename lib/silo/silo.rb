require 'silo/errors'
require 'yaml'

module FlightSilo
  class Silo
    class << self
      def all
        @all ||= user_silos + global_silos
      end

      def [](name)
        silo = all.find { |s| s.name == name }

        (silo || fetch(key)).tap do |s|
          if s.nil?
            raise NoSuchSiloError, "unknown silo: #{key}"
          end
        end
      end

      def create(type:, name:, global: false)
        raise UnknownSiloTypeError, "unknown silo type" if type.nil?

        silo_name = [name, type.name].join('@')

        begin
          raise SiloExistsError, "Silo '#{silo_name}' already exists" if self[silo_name]
        rescue NoSuchSiloError
          nil
        end

        silo = type.create(name: name, global: global)
      end
      
      def exists?(name)
        silo = all.find { |s| s.name == name }
        !!silo
      end
      
      def available_silos
        Config.public_silos # WIP: add user silos
      end

      private

      def fetch(key)
        all.find { |s| s.to_s == key }
      end

      def user_silos
        @user_silos ||= silos_for(Config.user_silos_path)
      end

      def global_silos
        @global_silos ||= silos_for(Config.global_silos_path)
      end

      def silos_for(path)
        [].tap do |a|
          Dir[File.join(path, '*.yaml')].sort.each do |d|
            md = YAML.load_file(d)
            a << Silo.new(md: md)
          end
        end
      end
    end

    attr_reader :name, :type, :global, :description

    def initialize(global: false, md: {})
      @name = md[:name]
      @type = Type[md[:type]]
      @description = md[:description]
    end
  end
end
