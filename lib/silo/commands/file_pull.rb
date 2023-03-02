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
        # OPTS:
        # [recursive]

        if args[0].match(/^[^:]*:[^:]*$/)
          silo_name, source = args[0].split(":")
        else
          silo_name = Config.default_silo
          source = args[0]
        end

        if args[1]
          dest = args[1]
        else
          dest = Dir.pwd
        end

        keep_parent = @options.recursive && source[-1] == "/"

        silo = Silo[silo_name]
        if @options.recursive
          source = File.join("/files/", source.to_s.chomp("/"), "/")
          raise "Remote directory '#{source.delete_prefix("/files")}' does not exist" unless silo.dir_exists?(source, silo.region)
        else
          source = File.join("/files/", source.to_s.chomp("/"))
          raise "Remote file '#{source.delete_prefix("/files")}' does not exist (use --recursive to pull directories)" unless silo.file_exists?(source, silo.region)
        end
        parent = File.expand_path("..", dest)
        raise "The parent directory '#{parent}' does not exist" unless File.directory?(parent)

        `mkdir #{dest}`
        dest = dest + "/" + File.basename(source) unless keep_parent
        recursive = @options.recursive ? " --recursive" : ""

        ENV["flight_SILO_types"] = "#{Config.root}/etc/types"
        response = `/bin/bash #{Config.root}/etc/types/#{Silo[silo_name].type.name}/actions/pull.sh #{silo_name} #{source} #{dest} #{Silo[silo_name].region}#{recursive}`
        puts "File(s) downloaded to #{dest}"
      end
    end
  end
end
