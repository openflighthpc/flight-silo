require 'silo/errors'

module FlightSilo
  class Silo
    # We might want this to be configurable
    DEFAULT_NAME = 'default'

    class << self
      def all
        @all ||= user_silos
      end

      def [](key)
        unless key.include?('@')
          silo = 
            fetch(key +"@#{DEFAULT_NAME}") ||
            silos.find { |e| e.to_s.start_with?(key + '@') }
        end

        (silo || fetch(key)).tap do  |e|
          if e.nil?
            raise NoSuchSiloError, "unknown silo: #{key}"
          end
        end
      end

      def create(type, name: DEFAULT_NAME)
        raise UnknownSiloTypeError, "unknown silo type" if type.nil?

        silo_name = [type.name, name].join('@')
        
        begin
          raise SiloExistsError, "silo already exists: #{silo_name}" if self[silo_name]
        rescue NoSuchSiloError
          nil
        end

        silo = type.create(name: name)
      end

      private

      def fetch(key)
        all.find { |s| s.to_s == key }
      end

      # So-named "user" silos because later we may allow
      # for globally defined silos
      def user_silos
        @user_silos ||= silos_for(Config.user_silos_path)
      end

      def silos_for(path)
        [].tap do |a|
          Dir[File.join(path, '*')].sort.each do |d|
            dir_name = File.basename(d)
            next unless File.directory?(d) && dir_name.match?(/.*\+.*/)
            type, name = dir_name.split('+')
            a << Silo.new(name: name, type: Type[type])
          end
        end
      end
    end

    attr_reader :name, :type

    def initialize(name:, type:)
      @name = name
      @type = type
    end
  end
end
