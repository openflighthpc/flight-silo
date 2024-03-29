# frozen_string_literal: true

require 'open3'

module FlightSilo
  module TarUtils
    def valid_tar_gz?(file)
      `tar -tzf #{file} >/dev/null 2>&1`
      $?.success?
    end

    def extract_tar_gz(file, dest, mkdir_p: false)
      dest = File.expand_path(dest)

      raise NoSuchDirectoryError, "Local directory '#{dest}' not found" unless mkdir_p

      FileUtils.mkdir_p(dest)

      stdout, stderr, status = Open3.capture3(
        "tar -xf #{file} -C #{dest}"
      )

      return status.success? if status.success?

      raise <<~ERROR.chomp

        Error extracting tarball '#{dest}':
        #{stderr}
      ERROR
    end
  end
end
