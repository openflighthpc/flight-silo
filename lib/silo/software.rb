require 'silo/errors'
require 'silo/table'
require 'yaml'
require 'json'
require 'active_support'
require 'active_support/number_helper'

module FlightSilo
  class Software
    FILE_UNITS = [:byte, :kb, :mb, :gb, :tb]

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
          latest.each do |s|
            case version_depth
            when :all
              t.headers 'Name', 'Version', 'Size'

              t.row(
                bold(Paint[s[:name], :cyan]),
                s[:versions].map(&:version).join("\n"),
                s[:versions].map(&:pretty_filesize).join("\n"),
              )
            else
              t.headers 'Name', 'Version'

              is_more = grouped[s[:name]].length > version_depth
              version_col = s[:versions].map(&:version).join(', ')
              version_col << '...' if is_more
              t.row(
                bold(Paint[s[:name], :cyan]),
                version_col
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

    def pretty_filesize
      ActiveSupport::NumberHelper::number_to_human_size(filesize)
    end

    attr_reader :name, :version, :filesize

    def initialize(name:, version:, filesize: nil)
      @name = name
      @version = Gem::Version.new(version)
      @filesize = filesize
    end
  end
end
