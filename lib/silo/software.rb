require 'silo/errors'
require 'silo/table'
require 'yaml'
require 'json'

module FlightSilo
  class Software
    include Comparable

    class << self
      def table_from(softwares=[], version_depth: 5)
        grouped = softwares.group_by(&:name)
        latest = grouped.map do |k,v|
          { k => v.sort_by(&:version).reverse.last(version_depth) }
        end.reduce({}, :merge)

        Table.new.tap do |t|
          t.headers 'Name', 'Version'
          latest.each do |k,v|
            t.row bold(Paint[k, :cyan]), v.map(&:version).join(', ')
          end
        end
      end

      private

      def bold(string)
        "\e[1m#{string}\e[22m"
      end
    end

    # Required for Comparable module
    def <=>(software)
      version <=> software.version
    end

    def dump_metadata
      {
        "name" => name,
        "version" => version.to_s
      }.to_json
    end

    attr_reader :name, :version

    def initialize(name:, version:)
      @name = name
      @version = Gem::Version.new(version)
    end
  end
end
