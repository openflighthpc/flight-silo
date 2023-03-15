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
require 'open3'
require 'tty-prompt'

module FlightSilo
  module Commands
    class RepoAdd < Command
      def run
        types = Type.all.map { |t| [t.description, t.name] }.to_h
        type_name = prompt.select("Provider type:", types)
        type = Type[type_name]

        is_public = prompt.yes?("Is silo public?")

        questions = type.questions

        metadata = ask_questions(questions[:metadata])
        credentials = ask_questions(questions[:credentials]) unless is_public

        puts "Obtaining silo details for '#{type_name}'..."

        # TODO: Might be worth removing `name` from questions, as they'll all require a name
        md = {
          'name' => metadata.delete("name"),
          'type' => type_name,
          'description' => '',
          'is_public' => is_public
        }.merge(credentials).merge(metadata)

        new_silo = Silo.new(md: md.dup)

        target = File.join(type.dir, 'cloud_metadata.yaml')
        new_silo.pull('cloud_metadata.yaml', target, false)

        # TODO: A lot of this logic ought to belong to the Silo class
        cloud_md = YAML.load_file(target)
        `rm #{target}`
        `mkdir -p #{Config.user_silos_path}`

        silo_path = File.join(Config.user_silos_path, new_silo.name) + ".yaml"
        File.open(silo_path, "w") { |file| file.write(md.merge(cloud_md).to_yaml) }

        puts "Silo added"
      end

      private

      def ask_questions(questions)
        prompt.collect do
          questions.each do |question|
            key(question[:id]).ask(question[:text]) do |q|
              q.required question[:validation][:required]
              if question[:validation].to_h.key?(:format)
                q.validate Regexp.new(question[:validation][:format])
                q.messages[:valid?] = question[:validation][:message]
              end
            end
          end
        end
      end

      def prompt
        @prompt ||= TTY::Prompt.new(help_color: :yellow)
      end
    end
  end
end
