require_relative '../lib/lock'

module MakeMe
  class App
    LOCK_FILE = File.join('tmp', 'printing.lock')
    LOCK = MakeMe::Lock.new LOCK_FILE

    get '/lock' do
      require_basic_auth
      if locked?
        halt 423, lock_data(:json => true)
      else
        status 200
        "Unlocked"
      end
    end

    delete '/lock' do
      require_basic_auth
      # If process is still running, don't allow an unlock
      if locked? && !File.exist?(PID_FILE)
        LOCK.unlock!
        status 200
        "Lock cleared!"
      else
        status 404
        "No lock found or still printing"
      end
    end

    helpers do
      def locked?
        LOCK.locked?
      end

      def lock_data(options={})
        defaults = {:json => false}
        options = defaults.merge options

        data = LOCK.read_lock {}

        if options[:json]
          Yajl::Encoder.encode(data)
        else
          data
        end
      end

      def lock!
        LOCK.lock!
      end
    end
  end
end
