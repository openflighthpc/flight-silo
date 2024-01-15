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
    class SoftwareDelete < Command
      include TarUtils

      def run
        # ARGS:
        # [name, version]
        #
        # OPTS:
        # [repo]

        name, version = args

        raise NoSuchSiloError, "Silo '#{silo_name}' not found" unless silo

        raise "Public silos cannot be modified." if silo.is_public

        unless silo.find_software(name, version)
          raise "Software '#{name}' version '#{version}' not found"
        end

        puts "Updating migration archives..."
        `mkdir -p #{Config.migration_dir}/temp`
        silo = Silo[silo_name]
        dest = File.join(Config.migration_dir, 'temp', "migration_#{silo.id}.yml")
        silo.pull('/migration.yml', dest)
        dto_item = SoftwareMigrationItem.new(name, version, nil, nil, silo.id)
        RepoMigration.new(dest, silo.id).delete(dto_item)
        silo.push(dest, '/migration.yml')
        File.delete(dest)
        Migration.delete(dto_item)

        software_path = File.join(
          'software',
          "#{name}~#{version}.software"
        )

        puts "Deleting software '#{name}' version '#{version}'..."

        silo.delete(software_path)

        puts "Deleted software '#{name}' version '#{version}'."        
      end

      private

      def silo_name
        @silo_name ||= @options.repo || Silo.default
      end

      def silo
        @silo ||= Silo[silo_name]
      end
    end
  end
end
