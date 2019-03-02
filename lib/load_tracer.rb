require 'binding_of_caller'
require 'load_tracer/formatter/default'
require 'load_tracer/formatter/dot'
require 'load_tracer/formatter/json'
require 'load_tracer/version'

module Kernel
  unless defined?(__original_require__)
    alias __original_require__ require
  end

  unless defined?(__original_require_relative__)
    alias __original_require_relative__ require_relative
  end

  unless defined?(__original_load__)
    alias __original_load__ load
  end

  unless defined?(__original_autoload__)
    alias __original_autoload__ autoload
  end

  def require(feature)
    __original_require__(feature)
  end

  def require_relative(relative_feature)
    binding.of_caller(1).eval("__original_require_relative__('#{relative_feature}')")
  end

  def load(file, priv = false)
    __original_load__(file, priv)
  end

  def autoload(const_name, feature)
    __original_autoload__(const_name, feature)
  end
end

class LoadTracer
  FileSpec = Struct.new(:name, :path, :dependencies, :reverse_dependencies, keyword_init: true)

  LOAD_METHODS = %i(require require_relative load autoload)

  def self.trace(format: nil, exclude_files: [])
    instance = new(exclude_files: exclude_files)
    instance.tracer.enable { yield }
    instance.report(format: format)
  end

  def initialize(exclude_files: [])
    @dependencies = Hash.new { |hash, key| hash[key] = [] }
    @reverse_dependencies = Hash.new { |hash, key| hash[key] = [] }
    @exclude_files = exclude_files
    @not_found_features = []
  end

  def tracer
    TracePoint.new(:call) do |tp|
      next unless LOAD_METHODS.include?(tp.method_id)
      next if tp.defined_class != ::Kernel
      next if tp.path != __FILE__

      bl = caller_locations[1]
      feature = get_feature(tp)

      if bl.absolute_path.nil?
        bl = find_caller_of_internal_library(feature)
      end

      next if @exclude_files.include?(File.basename(bl.absolute_path))

      path = find_path(feature) || find_path(File.expand_path(feature, File.dirname(bl.path)))

      if path.nil?
        @not_found_features << feature
        next
      end

      @dependencies[bl.absolute_path] << path
      @reverse_dependencies[path] << bl.absolute_path
    end
  end

  def report(format:)
    case format
    when :dot
      DotFormatter.export(
        dependencies: @dependencies
      )
    when :json
      JsonFormatter.export(
        dependencies: @dependencies,
        reverse_dependencies: @reverse_dependencies
      )
    else
      DefaultFormatter.export(
        dependencies: @dependencies,
        reverse_dependencies: @reverse_dependencies
      )
    end
  end

  private

  def get_feature(tp)
    params = tp.self.method(tp.method_id).parameters

    case tp.method_id
    when :require, :require_relative, :load
      tp.binding.local_variable_get(params.first.last)
    when :autoload
      tp.binding.local_variable_get(params.last.last)
    end
  end

  def find_path(feature)
    RubyVM.resolve_feature_path(feature).last
  rescue LoadError
    nil
  end

  def find_caller_of_internal_library(feature)
    index = caller_locations.find_index { |bl| bl.base_label == feature && bl.path == '<internal:prelude>' }
    caller_locations[index + 1]
  end
end
