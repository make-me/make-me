module MakeMe
  class Lock
    attr_reader :file

    def initialize(file)
      @file = file
    end

    ## High level API
    def locked?
      lock_key(:status, :unknown).to_sym == :locked
    end

    def lock!
      update_lock :status => :locked
    end

    def unlock!
      update_lock :status => :unlocked
    end

    ## I/O API
    def update_lock(data={})
      current = (read_lock || {}).merge data
      File.open(@file, 'w') do |f|
        Yajl::Encoder.encode(data, f)
      end
    end

    # Returns data from the lock file
    # By default, it parses the JSON, but if passed `false`, it will return the
    # raw data. An empty hash will be returned if the file is empty
    def read_lock(parse_json = true)
      if File.exists?(file)
        File.open(file) do |f|
          if parse_json
            Yajl::Parser.new(:symbolize_keys => true).parse(f)
          else
            f.read
          end
        end
      end
    end

    private
    def lock_key(key, default=nil)
      if read_lock.nil?
        default
      else
        read_lock[key.to_sym]
      end
    end
  end
end
