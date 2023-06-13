require 'silo/errors'
require 'yaml'
require 'json'

module FlightSilo
  class Software
    include Comparable

    # Required for Comparable module
    def <=>(software)
      version <=> software.version
    end

    def to_table_row
      [Paint[name, :cyan], version]
    end

    def dump_metadata
      {
        "name" => name,
        "description" => description,
        "version" => version.to_s,
        "filename" => filename
      }.to_json
    end

    attr_reader :name, :filename, :description, :version

    def initialize(name:, filename:, description: '', version:)
      @name = name
      @filename = filename
      @description = description
      @version = Gem::Version.new(version)
    end
  end
end
