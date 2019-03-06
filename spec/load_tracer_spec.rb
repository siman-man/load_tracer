RSpec.describe LoadTracer do
  describe '.trace' do
    it 'require' do
      result = LoadTracer.trace { require_relative 'samples/require_test' }
      fs1 = result.find { |fs| fs.name == 'require_test.rb' }
      fs2 = result.find { |fs| fs.name == 'set.rb' }
      fs3 = result.find { |fs| fs.name == 'load_tracer_spec.rb' }

      expect(file_names(fs1.dependencies)).to eq(['set.rb'])
      expect(file_names(fs2.reverse_dependencies)).to eq(['require_test.rb'])
      expect(fs3.reverse_dependencies).to eq([])
    end

    it 'require_relative' do
      result = LoadTracer.trace { require_relative 'samples/require_relative_test' }
      fs1 = result.find { |fs| fs.name == 'require_relative_test.rb' }
      fs2 = result.find { |fs| fs.name == 'foo.rb' }
      fs3 = result.find { |fs| fs.name == 'bar.rb' }

      expect(file_names(fs1.dependencies)).to eq(['foo.rb'])
      expect(file_names(fs2.dependencies)).to eq(['bar.rb'])
      expect(file_names(fs2.reverse_dependencies)).to eq(['require_relative_test.rb'])
      expect(file_names(fs3.dependencies)).to be_empty
      expect(file_names(fs3.reverse_dependencies)).to eq(['foo.rb'])
    end

    it 'load' do
      result = LoadTracer.trace { require_relative 'samples/load_test' }
      fs1 = result.find { |fs| fs.name == 'load_test.rb' }
      fs2 = result.find { |fs| fs.name == 'foo.rb' }

      expect(file_names(fs1.dependencies)).to eq(['foo.rb'])
      expect(file_names(fs2.reverse_dependencies)).to eq(['load_test.rb'])
    end

    it 'autoload' do
      result = LoadTracer.trace { require_relative 'samples/autoload_test' }
      fs1 = result.find { |fs| fs.name == 'autoload_test.rb' }
      fs2 = result.find { |fs| fs.name == 'bar.rb' }

      expect(file_names(fs1.dependencies)).to eq(['bar.rb'])
      expect(file_names(fs2.reverse_dependencies)).to eq(['autoload_test.rb'])
    end

    it 'auto require `pp`' do
      result = LoadTracer.trace { require_relative 'samples/internal_library_test' }
      fs1 = result.find { |fs| fs.name == 'internal_library_test.rb' }

      expect(file_names(fs1.dependencies)).to eq(['pp.rb'])
    end

    it 'already require feature' do
      require_relative 'samples/lib/foo'

      result = LoadTracer.trace { require_relative 'samples/already_require_feature_test' }
      fs1 = result.find { |fs| fs.name == 'foo.rb' }

      expect(file_names(fs1.dependencies)).to eq(['bar.rb'])
    end

    it 'export dot format' do
      result = LoadTracer.trace(format: :dot) { require_relative 'samples/dot_format_test' }

      expect = <<~DOT.chomp
        digraph file_dependencies {
          graph [ dpi = 200 ]

          "dot_format_test.rb" -> "foo.rb"
          "foo.rb" -> "bar.rb"
          "load_tracer_spec.rb" -> "dot_format_test.rb"
        }
      DOT

      expect(result).to eq(expect)
    end

    it 'export json format' do
      result = JSON.parse(LoadTracer.trace(format: :json) { require_relative 'samples/json_format_test' })

      expect(result[0]['name']).to eq('bar.rb')
    end
  end
end
