class LoadTracer
  class StaticChecker < LoadTracer
    def self.parse_file(path)
      new(path).trace
    end

    def initialize(path)
      @path = path
    end

    def trace(format: nil)
      @dependencies = Hash.new { |hash, key| hash[key] = [] }
      @reverse_dependencies = Hash.new { |hash, key| hash[key] = [] }
      @load_checked_features = Hash.new
      @not_found_features = []

      traverse(path: @path)

      report(format: format, dependencies: @dependencies, reverse_dependencies: @reverse_dependencies)
    end

    def traverse(path:)
      return if @load_checked_features[path]
      return if File.extname(path) != '.rb'

      @load_checked_features[path] = true
      ast = RubyVM::AbstractSyntaxTree.parse_file(path)
      features = search_load_features(ast: ast)

      features.each do |feature|
        feature_path = find_path(feature) || find_path(File.expand_path(feature, File.dirname(path)))

        if feature_path.nil?
          @not_found_features << feature
          next
        end

        traverse(path: feature_path)

        @dependencies[path] << feature_path
        @reverse_dependencies[feature_path] << path
      end
    end

    private

    def inspector(ast:, &block)
      ast.children.each do |child|
        next unless child.instance_of?(RubyVM::AbstractSyntaxTree::Node)

        yield child

        inspector(ast: child, &block)
      end
    end

    def search_load_features(ast:)
      features = []

      inspector(ast: ast) do |node|
        next if node.type != :FCALL

        method_id = node.children[0]

        next unless LOAD_METHODS.include?(method_id)

        feature = case method_id
                  when :require, :require_relative, :load
                    node.children[1].children[0].children[0]
                  when :autoload
                    node.children[1].children[1].children[0]
                  end

        features << feature if feature.instance_of?(String)
      end

      features
    end
  end
end
