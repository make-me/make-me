module PrintMe
  class Lock
    attr_reader :file

    def initialize(file)
      @file = file
    end

    def locked?
      File.exist?(@file) && File.read(@file)
    end

    def lock!
      File.open(@file, 'w') { |f| f.write "Currently printing" }
    end

    def unlock!
      File.exist?(@file) && File.delete(@file)
    end
  end
end
