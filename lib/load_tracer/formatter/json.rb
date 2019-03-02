require 'json'

class LoadTracer
  class JsonFormatter
    def self.export(dependencies:, reverse_dependencies:)
      report = DefaultFormatter.export(
        dependencies: dependencies,
        reverse_dependencies: reverse_dependencies
      )

      report.map(&:to_h).to_json
    end
  end
end
