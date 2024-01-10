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
require_relative '../tar_utils'

module FlightSilo
  module Commands
    class MigrationApply < Command
      include TarUtils

      def run
        archive = @options.archive || SoftwareMigration.enabled_archive
        raise "The given archive \'#{archive}\' does not exist" unless SoftwareMigration.list_all_archives.include?(archive)
        
        puts "Migration \'#{archive}\' Start..."
        failed = []
        SoftwareMigration.get_archive(archive).each do |m|
          puts ""
          begin
            silo = Silo.fetch_by_id(m['repo_id'])
            name = m['name']
            version = m['version']

            puts "migrating #{name} #{version}..."
            software_path = File.join(
              'software',
              "#{name}~#{version}.software"
            )

            tmp_path = File.join(
              '/tmp',
              "#{name}~#{version}~#{('a'..'z').to_a.shuffle[0,8].join}"
            )

            extract_path = m['path']

            # Check that the software doesn't already exist locally
            if !@options.overwrite && File.directory?(extract_path)
              raise <<~ERROR.chomp
              Already exists: '#{name}' version '#{version}' at path '#{extract_path}'.
              ERROR
            end

            # Pull software to /tmp
            silo.pull(software_path, tmp_path)

            # Extract software to software dir
            extract_tar_gz(tmp_path, extract_path, mkdir_p: true)

            puts "\'#{name}\' \'#{version}\' successfully migrated"
          rescue => e
            failed << "\'#{name} #{version}\'"
            puts Paint[e.message, :red]
          end
          puts ""
        end

        if failed.empty?
          puts Paint["Migration All Done √\n", :green]
        else
          puts "Migration process finished with the following items failed: #{failed.join(', ')}\n"
        end
      end
    end
  end
end
