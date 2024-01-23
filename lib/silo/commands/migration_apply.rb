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
        archive_id = @options.archive || Migration.enabled_archive
        archive = Migration.get_archive(archive_id)
        raise "The given archive \'#{archive_id}\' does not exist" unless archive
        items = archive.items

        puts "Validating Archive \'#{archive_id}\'...\n"
        failed_items = []
        missing_items = []
        missing_silos = []
        items.each do |i|
          silo = Silo.fetch_by_id(i.repo_id)
          if silo
            if i.is_software? && !silo.find_software(i.name, i.version)
              missing_items << i
              failed_items << i
            end
          else
            missing_silos << i.repo_name
            failed_items << i
          end
        end
        unless failed_items.empty?
          if @options.ignore_missing_item
            items -= failed_items
            puts "The following item(s) does not exist and will be ignored: #{failed_items.map { |i| "Software \'#{i.name} #{i.version}\'" }.join(', ')}"
          else
            raise "Migration failed! The following item(s) cannot be applied: #{failed_items.map { |i| "Software \'#{i.name} #{i.version}\'" }.join(', ')}. Caused by:\n#{missing_silos.map { |s| "\n- Silo \'#{s}\' not present." }.join()}#{missing_items.map { |i| "\n- Software \'#{i.name} #{i.version}\' not found in \'#{i.repo_name}\'." }.join()}\n"
          end
        end

        puts "Migration for archive \'#{archive_id}\' started..."
        failed = []
        items.each do |i|
          puts ""
          begin
            silo = Silo.fetch_by_id(i.repo_id)
            name = i.name
            version = i.version

            puts "Migrating software #{name} #{version}..."
            software_path = File.join(
              'software',
              "#{name}~#{version}.software"
            )

            tmp_path = File.join(
              '/tmp',
              "#{name}~#{version}~#{('a'..'z').to_a.shuffle[0,8].join}"
            )

            extract_dir = i.is_absolute ? i.path : File.join(Dir.home, i.path)

            cur = extract_dir
            while (!File.writable?(cur))
              raise "User does not have permission to create files in the directory '#{cur}'" if File.exists?(cur)
              cur = File.expand_path("..", cur)
            end

            # Check that the software doesn't already exist locally
            if !@options.overwrite && File.directory?(extract_dir)
              raise <<~ERROR.chomp
              Already exists: '#{name}' version '#{version}' at path '#{extract_dir}'.
              ERROR
            end

            # Pull software to /tmp
            silo.pull(software_path, tmp_path)

            # Extract software to software dir
            extract_tar_gz(tmp_path, extract_dir, mkdir_p: true)

            puts "\'#{name}\' \'#{version}\' successfully migrated"
          rescue => e
            failed << "\'Software #{name} #{version}\'" if i.is_software?
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
