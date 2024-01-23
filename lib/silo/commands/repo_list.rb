# frozen_string_literal: true

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
    class RepoList < Command
      def run
        if Silo.all.empty?
          puts 'No silos found.'
        else
          table = Table.new
          table.headers 'Name', 'Description', 'Platform', 'Public?', 'ID'
          Silo.all.each do |s|
            table.row (s.deleted? ? Paint[s.name, :yellow] : Paint[s.name, :cyan]),
                      Paint[s.description, :green],
                      Paint[s.type.name, :cyan],
                      s.is_public,
                      s.id.delete_prefix('flight-silo-').upcase
          end
          table.emit
        end
      end

      def prompt
        @prompt ||= TTY::Prompt.new(help_color: :yellow)
      end
    end
  end
end
