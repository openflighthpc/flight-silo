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
    class MigrationRemoveSoftware < Command
      def run
        raise "Options \'--archive\' and \'--all\' cannot be enabled at the same time." if @options.archive && @options.all

        name, version = args
        item = SoftwareMigrationItem.new(name, version, nil, nil, nil, nil)
        if @options.all
          hosting_repo_ids = Migration.remove_all(item)
          update_hosting_repos(hosting_repo_ids) if hosting_repo_ids
          puts Paint["Software \'#{name} #{version}\' migration record has been removed from all archives", :green]
        else
          archive_id = @options.archive || Migration.enabled_archive
          archive = Migration.get_archive(archive_id)
          if archive.has?(item)
            hosting_repo_id = Migration.remove(item, archive_id)
            update_hosting_repos([hosting_repo_id]) if hosting_repo_id
            puts Paint["Software \'#{name} #{version}\' migration record has been removed from archive \'#{archive_id}\'", :green]
          else
            puts "Software \'#{name} #{version}\' does not exist in archive \'#{archive_id}\'. Nothing has changed."
          end
        end
      end

      private

      def update_hosting_repos(repo_ids)
        repo_hashes = Migration.to_repo_hashes
        repo_ids.each do |repo_id|
          silo = Silo.fetch_by_id(repo_id)
          temp_repo_path = File.join(Config.migration_dir, 'temp', "migration_#{repo_id}.yml")
          repo_hash = repo_hashes[repo_id] || RepoMigration.new(temp_repo_path, repo_id).to_hash
          File.open(temp_repo_path, 'w') do |file|
            file.write(repo_hash.to_yaml)
          end
          silo.push(temp_repo_path, '/migration.yml')
          File.delete(temp_repo_path)
        end
      end
    end
  end
end
