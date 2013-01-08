module MakeMe
  class MiracleGrueConfigurator
    attr_reader :config

    def initialize(config)
      @config = defaults.merge(config)
    end

    def save(filename)
      File.open(filename, 'w') do |file|
        file.write Yajl::Encoder.encode(config, :pretty => true)
      end
    end

    def defaults
      root = File.realpath File.join (File.dirname __FILE__), "..", ".."
      File.open File.join "config", "grue-default.config" do |defaults|
        Yajl::Parser.new(:symbolize_keys => true).parse defaults
      end
    end
  end
end
