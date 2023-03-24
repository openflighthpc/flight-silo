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

        (silo || fetch(name))
      end

      def create(creds:, global: false)
        creds_copy = creds.clone
        name = creds_copy.delete("name")
        type = Type[creds_copy.delete("type")]
        self.check_prepared(type)

        unless get_silo(name: name, type: type, creds: creds_copy)&.empty?
          raise RemoteSiloExistsError, "Silo '#{name}' already exists on remote provider '#{type.name}'"
        end

        raise SiloExistsError, "Silo '#{name}' already exists" if self[name]

        id = "flight-silo-".tap do |v|
          8.times{v  << (97 + rand(25)).chr}
        end

        env = {
          'SILO_ID' => id,
          'SILO_NAME' => name
        }.merge(creds_copy)

        type.run_action('create.sh', env: env).chomp
      end

      def add(answers)
        h = answers.clone
        name = h.delete("name")

        type = Type[h.delete("type")]
        creds = h

        silo_id = get_silo(name: answers["name"], type: type, creds: creds)

        if silo_id.empty?
          raise "No silos found with given name."
        end

        env = {
          'SILO_NAME' => silo_id,
          'SILO_SOURCE' => 'cloud_metadata.yaml',
          'SILO_DEST' => File.join(type.dir, 'cloud_metadata.yaml'),
          'SILO_PUBLIC' => 'false',
          'SILO_RECURSIVE' => 'false'
        }.merge(creds)

        type.run_action('pull.sh', env: env)

        cloud_md = YAML.load_file("#{type.dir}/cloud_metadata.yaml")
        `rm "#{type.dir}/cloud_metadata.yaml"`
        `mkdir -p #{Config.user_silos_path}`
        md = answers.merge(cloud_md).merge({"id" => silo_id})
        File.open("#{Config.user_silos_path}/#{silo_id}.yaml", "w") { |file| file.write(md.to_yaml) }
      end

      # Takes a silo's friendly name and returns the id of the first accessible silo matching it
      def get_silo(name:, type:, creds:)
        check_prepared(type)
        env = {
          'SILO_NAME' => name
        }.merge(creds)

        type.run_action('get_silo.sh', env: env).chomp
      end

      def exists?(name)
        !!all.find { |s| s.name == name }
      end

      def default
        Config.user_data.fetch(:default_silo).tap do |d|
          raise "No default silo set!" if !d
        end
      end

      def remove_default
        Config.user_data.delete(:default_silo)
        Config.save_user_data
      end

      def set_default(silo_name)
        self[silo_name].tap do |silo|
          raise NoSuchSiloError, "Silo '#{name}' not found" unless silo

          Config.user_data.set(:default_silo, value: silo.name)
          Config.save_user_data
        end
      end

      def check_prepared(type)
        raise "Type '#{type.name}' is not prepared" unless type.prepared?
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
      self.class.check_prepared(@type)
      env = {
        'SILO_NAME' => @id,
        'SILO_PUBLIC' => @is_public.to_s,
        'SILO_PATH' => path
      }.merge(@creds)

      resp = run_action('dir_exists.sh', env: env).chomp
      resp == 'yes'
    end

    def remove
      File.delete("#{Config.user_silos_path}/#{@id}.yaml")
    end

    def file_exists?(path)
      self.class.check_prepared(@type)
      env = {
        'SILO_NAME' => @id,
        'SILO_PUBLIC' => @is_public.to_s,
        'SILO_PATH' => path
      }.merge(@creds)

      resp = run_action('file_exists.sh', env: env).chomp
      resp == 'yes'
    end

    def delete(path, recursive: false)
      self.class.check_prepared(@type)
      env = {
        'SILO_NAME' => @id,
        'SILO_PUBLIC' => @is_public.to_s,
        'SILO_PATH' => path,
        'SILO_RECURSIVE' => recursive.to_s
      }.merge(@creds)

      run_action('delete.sh', env: env).chomp
    end

    def list(path)
      self.class.check_prepared(@type)
      env = {
        'SILO_NAME' => @id,
        'SILO_PUBLIC' => @is_public.to_s,
        'SILO_PATH' => path
      }.merge(@creds)

      resp = run_action('list.sh', env: env).chomp

      data = YAML.load(resp)

      return [data["dirs"]&.map { |d| File.basename(d) },
              data["files"]&.map { |f| File.basename(f) }]
    end

    def pull(source, dest, recursive: false)
      self.class.check_prepared(@type)
      env = {
        'SILO_NAME' => @id,
        'SILO_SOURCE' => source,
        'SILO_DEST' => dest,
        'SILO_PUBLIC' => @is_public.to_s,
        'SILO_RECURSIVE' => recursive.to_s
      }.merge(@creds)

      run_action('pull.sh', env: env)
    end

    def delete_silo_upstream
      self.class.check_prepared(@type)
      env = {
        'SILO_NAME' => @id
      }.merge(@creds)

      run_action('delete_silo_upstream.sh', env: env)
    end

    def push(source, dest)
      self.class.check_prepared(@type)
      env = {
        'SILO_NAME' => @id,
        'SILO_SOURCE' => source,
        'SILO_DEST' => dest,
      }.merge(@creds)

      run_action('push.sh', env: env)
    end

    attr_reader :name, :type, :global, :description, :is_public, :creds, :id

    def initialize(global: false, md: {})
      @name = md.delete("name")
      @type = Type[md.delete("type")]
      @description = md.delete("description")
      @is_public = md.delete("is_public")
      @id = md.delete("id")
      
      @creds = md # Credentials are all unused metadata values
    end

    private

    def run_action(*args, **kwargs)
      type.run_action(*args, **kwargs)
    end
  end
end
