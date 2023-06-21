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
require 'json'

module FlightSilo
  module Commands
    class SoftwareSearch < Command
      def run
        # ARGS:
        # [name]

        raise NoSuchSiloError, "Silo '#{silo_name}' not found" unless silo

        matcher = Regexp.new(args[0].to_s) || /.*/
        softwares = silo.software_index.select { |s| s.name =~ matcher }

        kwargs = {
          version_depth: args[0] ? :all : nil
        }.reject { |k,v| v.nil? }

        raise "No softwares found" if softwares.empty?

        puts "Showing latest 5 versions..." unless args[0]

        Software.table_from(softwares, **kwargs).emit
      end

      private

      def silo_name
        @options.repo || Silo.default
      end

      def silo
        Silo[silo_name]
      end
    end
  end
end
