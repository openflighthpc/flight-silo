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
    class RepoAdd < Command
      def run
        answers = prompt.collect do
          type_name = key("type").ask("Provider type name:")
          type = Type[type_name]
          type.questions.each do |question|
            key(question[:id]).ask(question[:text]) do |q|
              q.required question[:validation][:required]
              if question[:validation].to_h.key?(:format)
                q.validate Regexp.new(question[:validation][:format])
                q.messages[:valid?] = question[:validation][:message]
              end
            end
          end
        end
        
        puts answers.inspect

        type = Type[answers["type"]]
        puts "Obtaining silo details for '#{answers["name"]}'..."

        type_dir = "#{Config.root}/etc/types/#{type.name}"
        ENV["flight_SILO_types"] = "#{Config.root}/etc/types"
        `/bin/bash #{type_dir}/actions/pull.sh #{answers["name"]} /cloud_metadata.yaml #{type_dir}/cloud_metadata.yaml #{answers["region"]} #{answers["access_key"]} #{answers["secret_key"]}`

        cloud_md = YAML.load_file("#{type_dir}/cloud_metadata.yaml")
        `rm "#{type_dir}/cloud_metadata.yaml"`
        `mkdir -p #{Config.user_silos_path}`
        File.open("#{Config.user_silos_path}/#{answers["name"]}.yaml", "w") { |file| file.write(cloud_md.merge(answers).to_yaml) }

        puts "Silo added"
      end

      def prompt
        @prompt ||= TTY::Prompt.new(help_color: :yellow)
      end
    end
  end
end
