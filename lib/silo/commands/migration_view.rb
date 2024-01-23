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
        archive = @options.archive || Migration.enabled_archive

        raise "The given archive \'#{archive}\' does not exist" unless Migration.get_archive(archive)

        unless @options.archive
          puts "\nArchives:"
          table = Table.new
          table.headers 'Archive', 'Status', 'Host Silo'
          Migration.archives.each do |a|
            table.row a.id, a.id == Migration.enabled_archive ? Paint["enabled", :green] : "", a.repo_id.nil? ? "Undefined" : Silo.fetch_by_id(a.repo_id).name
          end
          table.emit
          puts "\nEnabled archive details:"
        end

        if Migration.get_archive(archive).empty?
          puts "Archive \'#{archive}\' is empty."
        else
          table = Table.new
          table.headers 'Type', 'Name', 'Version', 'Path', 'Absolute', 'Silo Name'
          Migration.get_archive(archive).to_hash['items'].each do |i|
            table.row i['type'], i['name'], i['version'].nil? ? 'N/A' : i['version'], i['is_absolute'] ? i['path'] : '~' + i['path'], i['is_absolute'], i['repo_name']
          end
          table.emit
        end
        puts ""
      end
    end
  end
end
