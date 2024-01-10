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
require_relative '../migration'

module FlightSilo
  module Commands
    class MigrationView < Command
      def run
        archive = @options.archive || SoftwareMigration.enabled_archive

        raise "The given archive \'#{archive}\' does not exist" unless SoftwareMigration.list_all_archives.include?(archive)

        unless @options.archive
          puts "\nArchives:"
          table = Table.new
          table.headers 'Archive', 'Status', 'Main Silo'
          SoftwareMigration.list_all_archives.each do |a|
            main_repo = nil
            if SoftwareMigration.list_main_archives.include?(a)
              main_repo = SoftwareMigration.get_main_repo(a)
            elsif SoftwareMigration.list_restricted_archives.include?(a)
              main_repo = Paint['Restricted', :magenta]
            else
              main_repo = Paint['Undefined', :cyan]
            end
            table.row a, a == SoftwareMigration.enabled_archive ? Paint["enabled", :green] : "", main_repo
          end
          table.emit
          puts "#{archive} Archive Details:"
        end

        if SoftwareMigration.get_archive(archive).empty?
          puts "Archive #{archive} is empty."
        else
          table = Table.new
          table.headers 'Type', 'Name', 'Version', 'Path', 'Absolute', 'Repo ID'
          SoftwareMigration.get_archive(archive).each do |m|
            table.row m['type'], m['name'], m['version'], m['path'], m['absolute'], m['repo_id']
          end
          table.emit
        end
        puts ""
      end
    end
  end
end
