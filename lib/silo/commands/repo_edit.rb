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
require 'tty-prompt'

module FlightSilo
  module Commands
    class RepoEdit < Command
      def run
        raise "Silo '#{@args[0]}' not found" unless silo = Silo[@args[0]]
        raise "Cannot edit public silos" if silo.is_public

        prompt = TTY::Prompt.new(help_color: :yellow)

        answers = prompt.collect do
          key('name').ask("Silo name:") do |q|
            q.default silo.name
            q.required true
            q.validate Regexp.new("^[a-zA-Z0-9_\\-]+$")
            q.messages[:valid?] = 'Invalid silo name: %{value}. Must contain only alphanumeric characters, - and _'
          end
          key('description').ask("Silo description:") do |q|
            q.default silo.description
            q.required false
            q.messages[:valid?] = 'Invalid silo name: %{value}. Must contain only alphanumeric characters, - and _'
          end
        end
        puts "Updating silo details..."
        File.write('/tmp/#{silo.id}_cloud_metadata.yaml', answers.to_yaml)
        silo.push('/tmp/#{silo.id}_cloud_metadata.yaml', 'cloud_metadata.yaml')
        File.delete('/tmp/#{silo.id}_cloud_metadata.yaml')
        puts "Silo details updated"
      end
    end
  end
end
