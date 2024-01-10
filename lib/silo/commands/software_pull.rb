#==============================================================================
# Copyright (C) 2023-present Alces Flight Ltd.
#
# This file is part of Flight Silo.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Silo is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Silo. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Silo, please visit:
# https://github.com/openflighthpc/flight-silo
#==============================================================================
require_relative '../command'
require_relative '../silo'
require_relative '../tar_utils'
require 'json'

module FlightSilo
  module Commands
    class SoftwarePull < Command
      include TarUtils

      def run
        # ARGS:
        # [software, version]
        #
        # OPTS:
        # [ repo ]

        name, version = args

        software_path = File.join(
          'software',
          "#{name}~#{version}.software"
        )

        tmp_path = File.join(
          '/tmp',
          "#{name}~#{version}~#{random_string}"
        )

        raise NoSuchSiloError, "Silo '#{silo_name}' not found" unless silo

        unless silo.find_software(name, version)
          raise "Software '#{name}' version '#{version}' not found"
        end

        software_dir = @options.dir || Config.user_software_dir
        cur = software_dir
        while (!File.writable?(cur))
          raise "User does not have permission to create files in the directory '#{cur}'" if File.exists?(cur)
          cur = File.expand_path("..", cur)
        end
        extract_path = File.join(
          software_dir,
          name,
          version
        )
        absolute = File.absolute_path?(software_dir) || !File.expand_path(software_dir).start_with?(Dir.home)
        migration_dir = if absolute
          File.expand_path(extract_dir)
        else
          File.expand_path(extract_dir).sub(Dir.home, '')
        end

        # Check that the software doesn't already exist locally
        if !@options.overwrite && File.directory?(extract_dir)          
          error_msg = "Already exists: \'#{name}\' version \'#{version}\' at path \'#{extract_dir}\' (use --overwrite to bypass)."
          unless SoftwareMigration.get_archive.any? { |item| item['name'] == name && item['version'] == version } || (silo.is_public && SoftwareMigration.list_restricted_archives.include?(migration_item.archive))
            migration_item = SoftwareMigrationItem.new(name, version, migration_dir, absolute, silo.id)
            repo_items = SoftwareMigration.add(migration_item)
            error_msg += "The migration archive has been updated."
          end
          raise <<~ERROR.chomp

          #{error_msg}
          ERROR
        end

        # Pull software to /tmp
        puts "Downloading software '#{name}' version '#{version}'..."

        silo.pull(software_path, tmp_path)

        # Extract software to software dir
        puts "Extracting software to '#{software_dir}'..."

        extract_tar_gz(tmp_path, extract_dir, mkdir_p: true)

        puts "Extracted software '#{name}' version '#{version}' to '#{Config.user_software_dir}'..."

        puts "Updating local migration archive..."
        migration_item = SoftwareMigrationItem.new(name, version, extract_dir, true, silo.id)
        if silo.is_public && SoftwareMigration.list_restricted_archives.include?(migration_item.archive)
          puts "[Warning] This pull opration is not recorded to the migration archive #{migration_item.archive} since the repository is public and the archive is restricted."
        else
          repo_items = SoftwareMigration.add(migration_item)
        end

        puts "Extracted software '#{name}' version '#{version}' successfully pulled"
      ensure
        FileUtils.rm(tmp_path) if File.file?(tmp_path)
      end

      private

      def random_string(len=8)
        ('a'..'z').to_a.shuffle[0,len].join
      end

      def silo_name
        @silo_name ||= @options.repo || Silo.default
      end

      def silo
        @silo ||= Silo[silo_name]
      end
    end
  end
end
