module MakeMe
  class Normalizer
    def initialize(inputs, output, args)

      @inputs, @output, @args = inputs, output, args
    end

    def count
      @args[:count] || 1
    end

    def scale
      @args[:scale] || 1.0
    end

    def bounds
      @args[:bounds] || {
                          :length => (ENV['MAKE_ME_MAX_X'] || 285).to_f.to_s,
                          :width  => (ENV['MAKE_ME_MAX_Y'] || 153).to_f.to_s,
                          :height => (ENV['MAKE_ME_MAX_Z'] || 155).to_f.to_s,
                        }
    end

    def inputs
      @inputs || []
    end

    # Runs stltwalker with the given arguments and blocks. Returns if the
    # normalization worked properly
    def normalize!
      input_files = inputs * count
      args = ['-p', '-o', @output, "--scale=#{scale}"]
      if bounds
        args.concat([
                      '-L', bounds[:length],
                      '-W', bounds[:width],
                      '-H', bounds[:height]
                    ])
      end

      normalize = ['./vendor/stltwalker/stltwalker', *args, *input_files]
      begin
        pid = Process.spawn(*normalize, :err => :out, :out => [MakeMe::App::LOG_FILE, "w"])
        _pid, status = Process.wait2 pid

        status.exitstatus == 0
      rescue Errno::ENOENT
        # If we cannot find stltwalker, we fail
        false
      end
    end
  end
end
