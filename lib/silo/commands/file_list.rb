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
    class FileList < Command
      def run
        # ARGS:
        # [silo:dir]
        
        silo_name, dir = args[0].split(":")
        dir = "files/" + dir.delete_prefix("/")
        
        raise NoSuchSiloError, "Silo '#{silo_name}' not found" unless Silo.exists?(silo_name)
        
        ENV["flight_SILO_types"] = "#{Config.root}/etc/types"
        data = JSON.load(`/bin/bash #{Config.root}/etc/types/#{Silo[silo_name].type.name}/actions/list.sh #{silo_name} #{dir}`)
        
        # Type-specific
        if data == nil
          raise "Directory /#{dir} is empty, or doesn't exist"
        end
        files = data["Contents"]&.map{ |obj| obj["Key"] }[1..-1]
        dirs = data["CommonPrefixes"]&.map{ |obj| obj["Prefix"] }
        
        dirs&.each do |dir|
          puts Paint[bold(dir), :blue]
        end
        puts files
      end
      
      def bold(string)
        "\e[1m#{string}\e[22m" 
      end
    end
  end
end
