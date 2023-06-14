require 'open3'

module FlightSilo
  module TarUtils
    class << self
      def valid_tar_gz?(file)
        `tar -tzf #{file} >/dev/null`
        $?.success?
      end
    end
  end
end
