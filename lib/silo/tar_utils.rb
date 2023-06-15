require 'open3'

module FlightSilo
  module TarUtils
    def valid_tar_gz?(file)
      `tar -tzf #{file} >/dev/null 2>&1`
      $?.success?
    end

    def extract_tar_gz(file, dest, mkdir_p: false)
      dest = File.expand_path(dest)

      unless mkdir_p
        raise NoSuchDirectoryError, "Local directory '#{dest}' not found"
      end

      FileUtils.mkdir_p(dest)
      `tar -xf #{file} -C #{dest}`
      $?.success?
    end
  end
end
