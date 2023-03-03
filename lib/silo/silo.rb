require 'silo/errors'
require 'yaml'

module FlightSilo
  class Silo
    class << self
      def all
        @all ||= user_silos + global_silos + public_silos
      end

      def [](name)
        silo = all.find { |s| s.name == name }

        (silo || fetch(name)).tap do |s|
          if s.nil?
            raise NoSuchSiloError, "Silo '#{name}' not found"
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
        !!all.find { |s| s.name == name }
      end

      private

      def fetch(key)
        all.find { |s| s.to_s == key }
      end

      def public_silos
        @public_silos ||= silos_for(Config.public_silos_path)
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

    # Extra args are for type-specific required details, e.g. AWS region
    def dir_exists?(path, *args)
      extra_args = " " + args.join(" ")
      check_prepared
      ENV["flight_SILO_types"] = "#{Config.root}/etc/types"
      `/bin/bash #{Config.root}/etc/types/#{@type.name}/actions/dir_exists.sh #{@name} #{path}#{extra_args}`.chomp=="yes"
    end

    def file_exists?(path, *args)
      extra_args = " " + args.join(" ")
      check_prepared
      ENV["flight_SILO_types"] = "#{Config.root}/etc/types"
      `/bin/bash #{Config.root}/etc/types/#{@type.name}/actions/file_exists.sh #{@name} #{path}#{extra_args}`.chomp=="yes"
    end

    def check_prepared
      raise "Type '#{@type.name}' is not prepared" unless @type.prepared
    end

    attr_reader :name, :type, :global, :description, :is_public, :region, :access_key, :secret_key

    def initialize(global: false, md: {})
      @name = md["name"]
      @type = Type[md["type"]]
      @description = md["description"]
      @is_public = md["is_public"]

      @region = md["region"] || "none"          #
      @access_key = md["access_key"] || "none"  # --- AWS specific
      @secret_key = md["secret_key"] || "none" #
    end
  end
end
