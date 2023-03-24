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
    class FilePush < Command
      def run
        # ARGS:
        # [source, repo:dest]
        # OPTS:
        # [recursive]

        source = args[0]

        if args[1].match(/^[^:]*:[^:]*$/)
          silo_name, dest = args[1].split(":").map(&:to_s)
        else
          silo_name = Silo.default
          dest = args[0]
        end

        dest = "" if !dest

        silo = Silo[silo_name]

        raise "Public silos cannot be pushed to." if silo.is_public

        if File.directory?(source) && !@options.recursive
          error = <<~EOF
          Local file '#{source}' not found (use --recursive to push directories)
          EOF
          raise NoSuchFileError, error
        end

        dest = File.join(dest, File.basename(source)) if dest.end_with?('/')

        target = File.join("files/", dest)
        silo.push(source, target)
        path = Pathname.new(target)
        puts "File(s) pushed to jack-silo:#{dest}/"
      end
    end
  end
end
