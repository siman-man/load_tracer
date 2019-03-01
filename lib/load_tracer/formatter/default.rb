class LoadTracer
  class DefaultFormatter
    def self.export(dependencies:, reverse_dependencies:)
      report = dependencies.map do |path, deps|
        FileSpec.new(
          name: File.basename(path),
          path: path,
          dependencies: deps,
          reverse_dependencies: [],
        )
      end

      reverse_dependencies.each do |path, rdeps|
        fs = report.find { |fs| fs.path == path }

        if fs.nil?
          report << FileSpec.new(
            name: File.basename(path),
            path: path,
            dependencies: [],
            reverse_dependencies: rdeps,
          )
        else
          fs.reverse_dependencies = rdeps
        end
      end

      report.each do |fs|
        fs.dependencies.sort!.uniq!
        fs.reverse_dependencies.sort!.uniq!
      end

      report.sort_by(&:name)
    end
  end
end
