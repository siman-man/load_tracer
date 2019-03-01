require 'erb'

class LoadTracer
  class DotFormatter
    def self.export(dependencies:)
      new(dependencies: dependencies).export
    end

    def initialize(dependencies:)
      @dependencies = dependencies
      @template = File.read(File.expand_path('templates/default.dot.erb', __dir__))
    end

    def export
      graph_data = ERB.new(@template, nil, '-').result(binding)

      graph_data.lines.map(&:rstrip).join("\n")
    end

    private

    def graph_edges
      edges = []

      @dependencies.each do |from, deps|
        deps.each do |to|
          edges << [File.basename(from), File.basename(to)]
        end
      end

      edges.sort_by(&:first).uniq
    end
  end
end
