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
    class FilePull < Command
      def run
        # ARGS:
        # [silo:source, dest]
        
        silo_name, source = args[0].split(":")
        source = "files/" + source.delete_prefix("/")
        dest = File.expand_path(args[1])
        
        raise NoSuchSiloError, "Silo '#{silo_name}' not found" unless Silo.exists?(silo_name)
        raise "The directory '#{dest}' does not exist" unless File.directory?(dest)
        
        # ------ Check if file exists (type-specific)
        
        dest = dest + "/" + File.basename(source)
        
        ENV["flight_SILO_types"] = "#{Config.root}/etc/types"
        response = JSON.load(`/bin/bash #{Config.root}/etc/types/#{Silo[silo_name].type.name}/actions/pull.sh #{silo_name} #{source} #{dest} #{Silo[silo_name].region}`)
      end
    end
  end
end
