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
require_relative '../silo'

module FlightSilo
  module Commands
    class MigrationPush < Command
      def run
        `mkdir -p #{Config.migration_dir}/temp`

        main_repo_id = @options.main

        repo_migrations = SoftwareMigration.get_repo_migrations
        undefined_public_items = repo_migrations.delete('undefined_items')
        defined_public_archives = []
        undefined_archives = SoftwareMigration.list_undefined_archives
        undefined_archives.each do |ua|
          main_repo_item = SoftwareMigration.get_archive(ua).find { |item| !Silo[item['repo_id']].is_public }
          main_repo_id ||= !main_repo_item.nil? ? main_repo_item['repo_id'] : Silo.all
          .find { |s| !s.is_public }
          .id
          SoftwareMigration.set_main_repo(main_repo_id, ua)
          repo_migrations.each do |repo_id, rm|
            if repo_id == main_repo_id
              rm['main_archives'] << ua
            elsif rm['items'].any? { |ri| ri['archive'] == ua }
              rm['restricted_archives'] << ua
            end
          end
          defined_public_archives << ua
        end

        puts "The main repo of archives \'#{defined_public_archives.join(', ')} has been set to #{main_repo_id}\'"

        main_archives = SoftwareMigration.list_main_archives
        undefined_public_items.each do |item|
          archive = item['archive']
          repo_migrations[SoftwareMigration.get_main_repo(archive)]['items'] << item
        end

        repo_migrations.each do |repo_id, repo_migration_hash|
          silo = Silo.fetch_by_id(repo_id)
          puts "Updating #{silo.name} migration archives..."
          temp_repo_migration_path = File.join(Config.migration_dir, 'temp', "migration_#{silo.id}.yml")
          File.open(temp_repo_migration_path, 'w') do |file|
            file.write(repo_migration_hash.to_yaml)
          end
          silo.push(temp_repo_migration_path, '/migration.yml')
          File.delete(temp_repo_migration_path)
        end
        puts Paint["All Done √", :green]
      end
    end
  end
end
