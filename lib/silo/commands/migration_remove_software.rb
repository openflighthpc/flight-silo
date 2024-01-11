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
        if @options.all
          SoftwareMigration.remove_item(name, version)
          puts Paint["Software \'#{name} #{version}\' local migration record has been removed from all archives", :green]
        else
          archive = @options.archive || SoftwareMigration.enabled_archive
          SoftwareMigration.remove_item(name, version, archive)
          puts Paint["Software \'#{name} #{version}\' local migration record has been removed from archive #{archive}", :green]
        end
      end
    end
  end
end
