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

        set_default(silo) if default.nil?
      end

      def exists?(name)
        !!all.find { |s| s.name == name }
      end

      def default
        raise "No default silo set!"
        Config.user_data.fetch(:default_silo)
      end

      def remove_default
        Config.user_data.delete(:default_silo)
        Config.save_user_data
      end

      def set_default(silo_name)
        self[silo_name].tap do |silo|
          Config.user_data.set(:default_silo, value: silo.name)
          Config.save_user_data
        end
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

    def dir_exists?(path)
      check_prepared
      env = {
        'SILO_NAME' => @name,
        'SILO_PUBLIC' => @is_public.to_s,
        'SILO_PATH' => path
      }.merge(@creds)

      resp = run_action('dir_exists.sh', env: env).chomp
      resp == 'yes'
    end

    def file_exists?(path)
      credentials = @creds.values.join(" ")
      check_prepared
      ENV["flight_SILO_types"] = "#{Config.root}/etc/types"
      `/bin/bash #{Config.root}/etc/types/#{@type.name}/actions/file_exists.sh #{@name} #{@is_public} #{path} #{credentials}`.chomp=="yes"
    end

    def list(path)
      check_prepared
      env = {
        'SILO_NAME' => @name,
        'SILO_PUBLIC' => @is_public.to_s,
        'SILO_PATH' => path
      }.merge(@creds)

      resp = run_action('list.sh', env: env).chomp

      data = YAML.load(resp)

      return [data["dirs"]&.map { |d| File.basename(d) },
              data["files"]&.map { |f| File.basename(f) }]
    end 

    def pull(source, dest, recursive)
      credentials = @creds.values.join(" ")
      check_prepared
      ENV["flight_SILO_types"] = "#{Config.root}/etc/types"
      response = `/bin/bash #{Config.root}/etc/types/#{@type.name}/actions/pull.sh #{@name} #{@is_public} #{source} #{dest} #{recursive} #{credentials}`
    end

    def check_prepared
      raise "Type '#{@type.name}' is not prepared" unless @type.prepared?
    end

    attr_reader :name, :type, :global, :description, :is_public, :creds

    def initialize(global: false, md: {})
      @name = md.delete("name")
      @type = Type[md.delete("type")]
      @description = md.delete("description")
      @is_public = md.delete("is_public")
      
      @creds = md # Credentials are all unused metadata values
    end

    private

    def run_action(script, env: {})
      script = File.join(type.dir, 'actions', script)
      if File.exists?(script)
        with_clean_env do
          stdout, stderr, status = Open3.capture3(
            env.merge({ 'SILO_TYPE_DIR' => type.dir }),
            script
          )

          unless status.success?
            raise <<~OUT
            Error running action:
            #{stderr.chomp}
            OUT
          end

          return stdout
        end
      end
    end

    def with_clean_env(&block)
      if Kernel.const_defined?(:OpenFlight) && OpenFlight.respond_to?(:with_standard_env)
        OpenFlight.with_standard_env { block.call }
      else
        msg = Bundler.respond_to?(:with_unbundled_env) ? :with_unbundled_env : :with_clean_env
        Bundler.__send__(msg) { block.call }
      end
    end
  end
end
