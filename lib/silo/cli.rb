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
require_relative 'commands'
require_relative 'version'

require 'tty/reader'
require 'commander'

module FlightSilo
  module CLI
    PROGRAM_NAME = ENV.fetch('FLIGHT_PROGRAM_NAME','silo')

    extend Commander::CLI
    program :application, "Flight Silo"
    program :name, PROGRAM_NAME
    program :version, "v#{FlightSilo::VERSION}"
    program :description, 'Persistent cloud storage'
    program :help_paging, false
    default_command :help

    if ENV['TERM'] !~ /^xterm/ && ENV['TERM'] !~ /rxvt/
      Paint.mode = 0
    end

    class << self
      def cli_syntax(command, args_str = nil)
        command.syntax = [
          PROGRAM_NAME,
          command.name,
          args_str
        ].compact.join(' ')
      end
    end

    command "set-default" do |c|
      cli_syntax(c, '[SILO]')
      c.description = "Set or view the default silo"
      c.action Commands, :set_default
    end

    command "type avail" do |c|
      cli_syntax(c)
      c.description = "Show available backend providers"
      c.action Commands, :type_avail
    end

    if Process.euid == 0
      command "type prepare" do |c|
        cli_syntax(c, 'TYPE')
        c.description = "Prepare an available provider type for use"
        c.action Commands, :type_prepare
      end
    end

    command 'repo add' do |c|
      cli_syntax(c)
      c.description = "Connect an existing silo to your system"
      c.action Commands, :repo_add
    end

    command 'repo create' do |c|
      cli_syntax(c)
      c.description = 'Create a new storage silo'
      c.action Commands, :repo_create
    end

    command 'repo delete' do |c|
      cli_syntax(c, 'REPO')
      c.description = "Delete a remote storage silo. This action is permanent and cannot be undone."
      c.action Commands, :repo_delete
    end

    command 'repo edit' do |c|
      cli_syntax(c, 'REPO')
      c.description = "Edit the name and/or description of an existing silo"
      c.action Commands, :repo_edit
    end

    command 'repo remove' do |c|
      cli_syntax(c, 'REPO')
      c.description = "Remove an existing silo from your system"
      c.action Commands, :repo_remove
    end

    command 'repo list' do |c|
      cli_syntax(c)
      c.description = "List available existing silos"
      c.action Commands, :repo_list
    end

    command 'file delete' do |c|
      cli_syntax(c, 'REPO:FILE')
      c.description = "Delete the specified file from the given silo repository"
      c.action Commands, :file_delete
      c.slop.bool "-r", "--recursive", "Delete a directory and all contents"
    end

    command 'file list' do |c|
      cli_syntax(c, '[REPO:DIR]')
      c.description = "List user files in the specified directory"
      c.action Commands, :file_list
    end

    command 'file pull' do |c|
      cli_syntax(c, 'REPO:SOURCE [DEST]')
      c.description = "Download a file from a silo to this machine"
      c.action Commands, :file_pull
      c.slop.bool "-r", "--recursive", "Pull a directory and all contents"
    end

    command 'file push' do |c|
      cli_syntax(c, 'SOURCE [REPO:DEST]')
      c.description = "Upload a file from this machine to a silo"
      c.action Commands, :file_push
      c.slop.bool "-r", "--recursive", "Push a directory and all contents"
      c.slop.bool "--make-parent", "Create subdirectories upstream if they don't exist"
    end

    command 'software search' do |c|
      cli_syntax(c, '[NAME]')
      c.description = "List software binaries in a silo"
      c.slop.string '--repo', 'Override default silo'
      c.action Commands, :software_search
    end

    command 'software push' do |c|
      cli_syntax(c, 'FILE NAME VERSION')
      c.description = "Push a software binary to a silo"
      c.slop.string '--repo', 'Override default silo'
      c.slop.bool '--force', 'Overwrite existing software version'
      c.action Commands, :software_push
    end

    command 'software pull' do |c|
      cli_syntax(c, 'NAME VERSION')
      c.description = "Pull a software binary from a silo to your apps directory"
      c.slop.string '--repo', 'Override default silo'
      c.slop.boolean '--overwrite', 'Overwrite software locally if it exists'
      c.slop.string '--dir', 'Overwrite the software directory configuration'
      c.action Commands, :software_pull
    end

    command 'software delete' do |c|
      cli_syntax(c, 'NAME VERSION')
      c.description = "Delete a software binary from a silo"
      c.slop.string '--repo', 'Override default silo'
      c.action Commands, :software_delete
    end
  end
end
