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
require_relative '../migration'
require 'json'
require 'yaml'

module FlightSilo
  module Commands
    class SoftwarePush < Command
      include TarUtils

      def run
        # ARGS:
        # [software]
        #
        # OPTS:
        # [ repo ]

        raise NoSuchSiloError, "Silo '#{silo_name}' not found" unless silo
        raise NoSuchFileError, "File '#{args[0]}' not found" unless software_path

        raise "Public silos cannot be pushed to." if silo.is_public

        unless File.basename(software_path).end_with?('.tar.gz')
          raise "Invalid target; must end with '.tar.gz': #{software_path}"
        end

        name, version = args[1..2]

        unless name.match(/^[a-zA-Z0-9\-]+$/)
          raise "Software name must contain only alphanumeric characters and hyphens."
        end

        begin
          Gem::Version.new(version)
        rescue ArgumentError
          raise "Malformed version string: '#{version}'"
        end

        upstream_name = "#{name}~#{version}.software"

        if !@options.force && silo.find_software(name, version)

          error_msg = "Already exists: \'#{name}\' version \'#{version}\' on silo \'#{silo_name}\' (use --force to bypass)."
          unless SoftwareMigration.get_archive.exist? { |item| item['name'] == name && item['version'] == version }
            migration_item = MigrationItem.new('software', name, version, software_path, true, silo.id)
            repo_items = SoftwareMigration.add(migration_item)
            error_msg += "The migration archive has been updated."
          end

          raise <<~ERROR.chomp

          #{error_msg}
          ERROR
        end

        puts "Uploading software '#{name}' version '#{version}'..."

        silo.push(
          software_path,
          "software/#{upstream_name}"
        )

        puts "Updating local migration archive..."
        migration_item = MigrationItem.new('software', name, version, software_path, true, silo.id)
        repo_items = SoftwareMigration.add(migration_item)

        puts "Uploaded software '#{name}' version '#{version}'."
      end

      private

      def software_path
        @software_path ||= File.expand_path(args[0]).tap do |s|
          return nil unless File.file?(s)
        end
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
