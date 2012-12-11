module PrintMe
  class App
    LOCK_FILE = File.join('tmp', 'printing.lock')

    get '/public_lock' do
      # doesn't expose contents of lockfile, i assume that's why /lock is authed
      if locked?
        status 423
        "Locked"
      else
        status 200
        "Unlocked"
      end
    end

    get '/lock' do
      require_basic_auth
      if locked?
        halt 423, locked?
      else
        status 200
        "Unlocked"
      end
    end

    post '/unlock' do
      require_basic_auth
      # If process is still running, don't allow an unlock
      if File.exist?(LOCK_FILE) && !File.exist?(PID_FILE)
        File.delete(LOCK_FILE)
        status 200
        "Lock cleared!"
      else
        status 404
        "No lock found"
      end
    end

    helpers do
      def locked?
        File.exist?(LOCK_FILE) && File.read(LOCK_FILE)
      end

      def lock!
        File.open(LOCK_FILE, 'w') { |f| f.write "Currently printing" }
      end
    end
  end
end
