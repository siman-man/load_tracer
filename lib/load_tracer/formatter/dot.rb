require 'erb'
require 'pathname'

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
      graph_data = ERB.new(@template, trim_mode: '-').result(binding)

      graph_data.lines.map(&:rstrip).join("\n")
    end

    private

    def graph_edges
      @dependencies.flat_map do |from, deps|
        label1 = File.basename(from)

        deps.map do |to|
          label2 = File.basename(to)

          [
            duplicated_label_names.include?(label1) ? node_label(from) : label1,
            duplicated_label_names.include?(label2) ? node_label(to) : label2,
          ]
        end
      end.sort_by(&:first).uniq
    end

    def duplicated_label_names
      return @_duplicate_names if @_duplicate_names

      checked = Hash.new
      @_duplicate_names = []

      @dependencies.each do |from, deps|
        label1 = File.basename(from)
        @_duplicate_names << label1 if checked[label1]
        checked[label1] = true

        deps.each do |to|
          label2 = File.basename(to)

          @_duplicate_names << label2 if label1 == label2
        end
      end

      @_duplicate_names.uniq!
      @_duplicate_names
    end

    def node_label(absolute_path)
      s, _, t = Pathname.new(absolute_path).ascend.take(3)
      s.relative_path_from(t).to_s
    end
  end
end
