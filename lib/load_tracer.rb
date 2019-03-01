require 'binding_of_caller'
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

  def self.trace
    instance = new
    instance.tracer.enable { yield }
    instance.report
  end

  def initialize
    @dependencies = Hash.new { |hash, key| hash[key] = [] }
    @reverse_dependencies = Hash.new { |hash, key| hash[key] = [] }
  end

  def tracer
    TracePoint.new(:call) do |tp|
      next unless LOAD_METHODS.include?(tp.method_id)
      next if tp.defined_class != ::Kernel
      next if tp.path != __FILE__

      case tp.event
      when :call
        bl = caller_locations[1]
        feature = get_feature(tp)

        if bl.absolute_path.nil?
          bl = find_caller_of_internal_library(feature)
        end

        path = find_path(feature) || find_path(File.expand_path(feature, File.dirname(bl.path)))

        raise LoadError.new("cannot load such file -- #{feature}") if path.nil?

        @dependencies[bl.absolute_path] << path
        @reverse_dependencies[path] << bl.absolute_path
      end
    end
  end

  def report
    file_specs = @dependencies.map do |path, deps|
      FileSpec.new(
        name: File.basename(path),
        path: path,
        dependencies: deps,
        reverse_dependencies: [],
      )
    end

    @reverse_dependencies.each do |path, rdeps|
      fs = file_specs.find { |fs| fs.path == path }

      if fs.nil?
        file_specs << FileSpec.new(
          name: File.basename(path),
          path: path,
          dependencies: [],
          reverse_dependencies: rdeps,
        )
      else
        fs.reverse_dependencies = rdeps
      end
    end

    file_specs.each do |fs|
      fs.dependencies.sort!.uniq!
      fs.reverse_dependencies.sort!.uniq!
    end

    file_specs
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
