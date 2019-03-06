RSpec.describe LoadTracer::StaticChecker do
  describe '.parse_file' do
    it 'require test' do
      result = LoadTracer::StaticChecker.parse_file(File.expand_path('samples/require_test.rb', __dir__))
      fs1 = result.find { |fs| fs.name == 'require_test.rb' }
      fs2 = result.find { |fs| fs.name == 'set.rb' }

      expect(file_names(fs1.dependencies)).to eq(['set.rb'])
      expect(file_names(fs2.reverse_dependencies)).to eq(['require_test.rb'])
    end

    it 'require_relative' do
      result = LoadTracer::StaticChecker.parse_file(File.expand_path('samples/require_relative_test.rb', __dir__))
      fs1 = result.find { |fs| fs.name == 'require_relative_test.rb' }
      fs2 = result.find { |fs| fs.name == 'foo.rb' }
      fs3 = result.find { |fs| fs.name == 'bar.rb' }

      expect(file_names(fs1.dependencies)).to eq(['foo.rb'])
      expect(file_names(fs2.dependencies)).to eq(['bar.rb'])
      expect(file_names(fs2.reverse_dependencies)).to eq(['require_relative_test.rb'])
      expect(file_names(fs3.dependencies)).to be_empty
      expect(file_names(fs3.reverse_dependencies)).to eq(['foo.rb'])
    end
  end
end

