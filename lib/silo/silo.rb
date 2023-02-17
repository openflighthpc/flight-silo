require 'silo/errors'

module FlightSilo
  class Silo
    class << self
      def all
        @all ||= user_silos + global_silos
      end

      def [](key)
        # If no type is given, there could be multiple silos with
        # the same name. In this case, the silo names will be listed
        # alphabetically and the first one will be chosen; therefore, the
        # returned silo will be the one with the alphabetically earliest
        # type name.
        unless key.include?('@')
          silo = all.find { |s| s.to_s.start_with?(key + '@') }
        end

        (silo || fetch(key)).tap do  |s|
          if s.nil?
            raise NoSuchSiloError, "unknown silo: #{key}"
          end
        end
      end

      def create(type:, name:, global: false)
        raise UnknownSiloTypeError, "unknown silo type" if type.nil?

        silo_name = [name, type.name].join('@')
        
        begin
          raise SiloExistsError, "silo already exists: #{silo_name}" if self[silo_name]
        rescue NoSuchSiloError
          nil
        end

        silo = type.create(name: name, global: global)
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
          Dir[File.join(path, '*')].sort.each do |d|
            dir_name = File.basename(d)
            next unless File.directory?(d) && dir_name.match?(/.*\+.*/)
            name, type = dir_name.split('+')
            a << Silo.new(name: name, type: Type[type])
          end
        end
      end
    end

    attr_reader :name, :type, :global

    def initialize(name:, type:, global: false)
      @name = name
      @type = type
    end
  end
end
