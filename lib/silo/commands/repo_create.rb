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

module FlightSilo
  module Commands
    class RepoCreate < Command
      def run
        types = Type.all.map { |t| [t.description, t.name] }.to_h
        type_name = prompt.select('Provider type:', types)
        type = Type[type_name]

        Silo.check_prepared(type)

        questions = type.questions

        metadata = ask_questions(questions[:metadata])
        credentials = ask_questions(questions[:credentials])

        answers = metadata.merge(credentials)
        answers['type'] = type_name

        puts 'Creating silo...'
        Silo.create(creds: answers)
        puts 'Silo created'

        silo_name = answers['name']
        puts "Obtaining silo details for '#{silo_name}'..."
        Silo.add(answers)

        Silo.reload_all
        silo = Silo[silo_name]
        migration_path = File.join(Config.migration_dir.to_s, 'temp', "migration_#{silo.id}.yml")
        RepoMigration.new(migration_path, silo.id)
        silo.push(migration_path, 'migration.yml')
        File.delete(migration_path)
        puts 'Silo added'
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
