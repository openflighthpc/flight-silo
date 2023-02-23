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
require_relative '../type'

module FlightSilo
  module Commands
    class RepoAvail < Command
      def run
        all_silos = Config.public_silos # Need to add user silos to this later
        
        if all_silos.empty?
          puts "No silos found."
        else
          table = Table.new
          table.headers 'Name', 'Description', 'Platform', 'Public?', 'Added?'
          all_silos.each do |s|
            table.row Paint[s["name"], :cyan],
                      Paint[s["description"], :green],
                      Paint[Type[s["type"]].name, :cyan],
                      s["is_public"],
                      Silo.exists?(s["name"])
          end
          table.emit
        end
      end
    end
  end
end
