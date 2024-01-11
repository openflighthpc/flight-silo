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
    class MigrationPull < Command
      def run
        
        silo = Silo[args[0]]

        raise "Silo #{args[0]} does not exist!" unless silo

        puts "Obtaining silo migration archives..."
        `mkdir -p #{Config.migration_dir}/temp`
        silo = Silo[silo_name]
        dest = File.join(Config.migration_dir, 'temp', "migration_#{silo.id}.yml")
        silo.pull('/migration.yml', dest)
        SoftwareMigration.merge(silo.id, YAML.load_file(dest))
        File.delete(dest)

        puts Paint["Done √", :green]
      end
    end
  end
end
