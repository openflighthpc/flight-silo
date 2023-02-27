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

module FlightSilo
  module Commands
    class RepoAdd < Command
      def run
        # ARGS:
        # [name]
        
        name = @args[0]
        if Silo.exists?(name)
          raise SiloExistsError, "Silo '#{name}' has already been added"
        end
        
        silo_data = Silo.all.find{ |s| s['name'] == name }
        raise NoSuchSiloError, "Silo '#{name}' not found" unless silo_data
        
        `mkdir -p #{Config.user_silos_path}`
        File.open("#{Config.user_silos_path}/#{name}.yaml", "w") { |file| file.write(silo_data.to_yaml) }
        
        # Ask config/credentials questions here
        
        puts "Silo added"
      end
    end
  end
end
