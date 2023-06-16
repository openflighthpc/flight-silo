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
          versions = v.sort_by(&:version).reverse
          case version_depth
          when :all
            [ { name: k, versions: versions } ]
          else
            [ { name: k, versions: versions.first(version_depth) } ]
          end
        end.reduce([], :<<).flatten

        Table.new.tap do |t|
          t.headers 'Name', 'Version'
          latest.each do |s|
            case version_depth
            when :all
              t.row(
                bold(Paint[s[:name], :cyan]),
                s[:versions].map(&:version).join("\n")
              )
            else
              t.row(
                bold(Paint[s[:name], :cyan]),
                s[:versions].map(&:version).join(', ')
              )
            end
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
