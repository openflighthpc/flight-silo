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
require 'xdg'
require 'tty-config'
require 'fileutils'

module FlightSilo
  module Config
    class << self
      SILO_DIR_SUFFIX = File.join('flight','silo')

      def data
        @data ||= TTY::Config.new.tap do |cfg|
          cfg.append_path(File.join(root, 'etc'))
          begin
            cfg.read
          rescue TTY::Config::ReadError
            nil
          end
        end
      end

      def save_data
        FileUtils.mkdir_p(File.join(root, 'etc'))
        data.write(force: true)
      end

      def data_writable?
        File.writable?(File.join(root, 'etc'))
      end

      def user_data
        @user_data ||= TTY::Config.new.tap do |cfg|
          xdg_config.all.map do |p|
            File.join(p, SILO_DIR_SUFFIX)
          end.each(&cfg.method(:append_path))
          begin
            cfg.read
          rescue TTY::Config::ReadError
            nil
          end
        end
      end

      def save_user_data
        FileUtils.mkdir_p(
          File.join(
            xdg_config.home,
            SILO_DIR_SUFFIX
          )
        )
        user_data.write(force: true)
      end

      def path
        config_path_provider.path ||
          config_path_provider.paths.first
      end

      def root
        @root ||= File.expand_path(File.join(__dir__, '..', '..'))
      end

      def type_paths
        @type_paths ||=
          data.fetch(
            :type_paths,
            default: [
              'etc/types'
            ]
          ).map { |p| File.expand_path(p, Config.root) }
      end

      def user_silos_path
        @user_silos_path ||= File.join(xdg_data.home, SILO_DIR_SUFFIX, "silos")
      end

      def global_silos_path
        @global_silos_path ||= File.expand_path(
          data.fetch(
            :global_silos_path,
            default: 'var/lib/silos'
          ),
          Config.root
        )
      end

      def public_silos_path
        @public_silos_path ||= File.join(Config.root, 'etc', 'public_silos')
      end

      def global_software_dir
        @global_software_dir ||= File.expand_path(
          data.fetch(
            :software_dir,
            default: File.join(xdg_data.home, SILO_DIR_SUFFIX, 'software')
          ),
          Config.root
        )
      end

      def user_software_dir
        @user_software_dir ||= 
          ENV['flight_SILO_software_dir'] ||
            File.expand_path(
              user_data.fetch(
                :software_dir,
                default: global_software_dir
              ),
              Config.root
            )
      end

      def force_refresh
        data.fetch(:force_refresh, default: false)
      end

      def migration_dir
        @migration_dir ||=
          ENV['flight_SILO_migration_path'] ||
            user_silos_path
      end

      private

      def xdg_config
        @xdg_config ||= XDG::Config.new
      end

      def xdg_data
        @xdg_data ||= XDG::Data.new
      end

      def xdg_cache
        @xdg_cache ||= XDG::Cache.new
      end
    end
  end
end
