module FlightSilo
  class Silo
    class << self
      def all
        @all ||= user_silos
      end

      private

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
