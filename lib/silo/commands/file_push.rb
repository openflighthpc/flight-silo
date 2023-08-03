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

        raise InvalidFileNameError, "Target destination '#{args[1]}' contains invalid symbol" unless args[1].nil? || args[1].match?(/^[^:]+(:[^:]+)?$/)
        
        # standardize args[1] to [silo_name, dest]
        split_args = args[1]&.split(":", 2)&.map(&:to_s) || ['']
        split_args.unshift(Silo.default) if split_args.size == 1
        
        silo_name, dest = split_args

        silo = Silo[silo_name]
        raise NoSuchSiloError, "Silo '#{silo_name}' not found" unless silo

        raise "Public silos cannot be pushed to." if silo.is_public

        move_contents = source[-1] == '/'
        source = File.expand_path(source)

        if @options.recursive
          if !File.directory?(source)
            raise NoSuchDirectoryError, "Local directory '#{source}' not found"
          end

          if move_contents
            target = File.join('files', dest.chomp('/'), '/')
            out = "Contents of local directory '#{source}' copied to remote '#{target.delete_prefix('files/')}'"
          else
            target = File.join('files', dest.chomp('/'), File.basename(source), '/')
            out = "Local directory '#{source}' copied to remote '/#{target.delete_prefix('files/')}'"
          end
        else
          if !File.file?(source)
            error = <<~EOF.chomp
            Local file '#{source}' not found (use --recursive to push directories)
            EOF
            raise NoSuchFileError, error
          end

          if dest.empty? || dest[-1] =='/'
            target = File.join('files', dest.squeeze('/'), File.basename(source))
          else
            target = File.join('files', dest.squeeze('/'))
          end

          parent_dir = dest.split("/", -1)[0..-3].join("/")
          unless silo.dir_exists?(parent_dir) || @options.make_parent
            raise NoSuchDirectoryError, "Remote directory '#{parent_dir}' not found"
          end

          out = "Local file '#{source}' copied to remote '/#{target.delete_prefix('files/')}'"
        end

        silo.push(source, target, recursive: @options.recursive)
        puts out
      end
    end
  end
end
