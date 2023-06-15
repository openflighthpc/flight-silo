require 'open3'

module FlightSilo
  module TarUtils
    def valid_tar_gz?(file)
      `tar -tzf #{file} >/dev/null 2>&1`
      $?.success?
    end

    def extract_tar_gz(file, dest)
      `tar -xf #{file} -C #{File.expand_path(dest)}`
      $?.success?
    end
  end
end
