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
          silo_name, source = args[0].split(':')
        else
          silo_name = Silo.default
          source = args[0]
        end

        dest = args[1] || Dir.pwd + '/'

        keep_parent = source[-1] == '/'

        silo = Silo[silo_name]
        raise NoSuchSiloError, "Silo '#{name}' not found" unless silo

        if @options.recursive
          source = File.join('files/', source.to_s.chomp('/'), '/')
          raise NoSuchDirectoryError, "Remote directory '#{source.delete_prefix('files/')}' not found" unless silo.dir_exists?(source)
        else
          source = File.join('files/', source.to_s.chomp('/'))
          raise NoSuchFileError, "Remote file '#{source.delete_prefix('files/')}' not found (use --recursive to pull directories)" unless silo.file_exists?(source)
        end
        parent = File.expand_path('..', dest)
        raise NoSuchDirectoryError, "Parent directory '#{parent}' not found" unless File.directory?(parent)

        puts "Pulling '#{silo.name}:#{source.delete_prefix('files')}' into '#{dest}'..."

        if @options.recursive
          `mkdir #{dest} >/dev/null 2>&1`
          dest = File.expand_path(File.join(dest, File.basename(source))) unless keep_parent
        elsif dest[-1] == '/'
          `mkdir #{dest} >/dev/null 2>&1`
          dest = File.expand_path(File.join(dest, File.basename(source)))
        end

        silo.pull(source, dest, recursive: @options.recursive)
        puts "File(s) downloaded to #{dest}"
      end
    end
  end
end
