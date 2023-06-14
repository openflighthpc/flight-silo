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

require 'yaml'
require 'open3'
require 'tty-prompt'

module FlightSilo
  module Commands
    class RepoDelete < Command
      def run
        raise "Silo '#{@args[0]}' not found" unless silo = Silo[@args[0]]
        raise "Cannot delete public silos" if silo.is_public
        puts <<HEREDOC

You are about to delete silo '#{silo.name}' (Silo ID #{silo.id[-8..-1].upcase})
This action is permanent and will erase the silo and all contents.
Once performed, this cannot be undone.
If you only want to remove references to the silo from your local system, you should use the 'repo remove' command instead

If you understand the above and still wish to delete this silo, type 'delete' below.
HEREDOC
        print "> "
        response = STDIN.gets.chomp
        raise "Response not correct, silo deletion aborted" unless response == "delete"
        silo.delete_silo_upstream
        silo.remove
        puts "Silo '#{silo.name}' deleted successfully"
      end
    end
  end
end
