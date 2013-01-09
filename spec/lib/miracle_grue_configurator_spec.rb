require 'spec_helper'

describe MakeMe::MiracleGrueConfigurator do
  describe 'initialization' do
    it 'has a sane default from the config' do
      expect(described_class.new.config[:infillDensity]).to eq(0.05)
    end

    it 'can overwrite a default' do
      density = 0.10
      configurator = described_class.new({:infillDensity => density})
      expect(configurator.config[:infillDensity]).to eq(density)
    end
  end
end
