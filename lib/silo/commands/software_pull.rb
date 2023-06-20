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
require_relative '../tar_utils'
require 'json'

module FlightSilo
  module Commands
    class SoftwarePull < Command
      include TarUtils

      def run
        # ARGS:
        # [software, version]
        #
        # OPTS:
        # [ repo ]

        name, version = args

        raise NoSuchSiloError, "Silo '#{silo_name}' not found" unless silo

        software_path = File.join(
          'software',
          "#{name}~#{version}.software"
        )

        tmp_path = File.join(
          '/tmp',
          "#{name}~#{version}~#{random_string}"
        )

        unless silo.find_software(name, version)
          raise "Software '#{name}' version '#{version}' not found"
        end

        extract_path = File.join(
          Config.user_software_dir,
          name,
          version
        )

        # Check that the software doesn't already exist locally
        if !@options.overwrite && File.directory?(extract_path)
          raise <<~ERROR.chomp

          Already exists: '#{name}' version '#{version}' at path '#{extract_path}' (use --overwrite to bypass)
          ERROR
        end

        # Pull software to /tmp
        puts "Downloading software '#{name}' version '#{version}'..."

        silo.pull(software_path, tmp_path)

        # Extract software to software dir
        puts "Extracting software to '#{Config.user_software_dir}'..."

        extract_tar_gz(tmp_path, extract_path, mkdir_p: true)

        puts "Extracted software '#{name}' version '#{version} to '#{Config.user_software_dir}'..."
      ensure
        FileUtils.rm(tmp_path) if File.file?(tmp_path)
      end

      private

      def random_string(len=8)
        ('a'..'z').to_a.shuffle[0,len].join
      end

      def silo_name
        @silo_name ||= @options.repo || Silo.default
      end

      def silo
        @silo ||= Silo[silo_name]
      end
    end
  end
end
