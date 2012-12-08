#!/usr/bin/env ruby

require 'bundler'
Bundler.require
require_relative 'lib/download'

module PrintMe
  class App < Sinatra::Base
    LOCK_FILE = File.join('tmp', 'printing.lock')
    PID_FILE  = File.join('tmp', 'make.pid')
    LOG_FILE  = File.join('tmp', 'make.log')

    ## Config
    set :static, true

    basic_auth do
      realm "The 3rd Dimension"
      username 'hubot'
      password 'isalive'
    end

    ## Helpers

    def locked?
      File.exist?(LOCK_FILE) && File.read(LOCK_FILE)
    end

    def progress
      progress = 0
      File.readlines(LOG_FILE).each do |line|
        matches = line.strip.scan /Sent \d+\/\d+ \[(\d+)%\]/
        puts line.inspect
        puts matches.inspect
        matches.length > 0 && progress = matches[0][0].to_i
      end
      progress
    end

    ## Routes/Public
    get '/' do
      @is_locked = locked?
      begin
        @current_log = File.read(LOG_FILE)
      rescue Errno::ENOENT
      end
      @progress = progress
      erb :index
    end

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

    get '/photo' do
      imagesnap = File.join(File.dirname(__FILE__), '..', 'vendor', 'imagesnap', 'imagesnap')

      out_name = 'snap_' + Time.now.to_i.to_s + ".jpg"
      out_dir = File.join(File.dirname(__FILE__), "public")

      Process.wait Process.spawn(imagesnap, File.join(out_dir, out_name))

      redirect out_name
    end

    get '/progress' do
      progress
    end

    ## Routes/Authed
    post '/print' do
      require_basic_auth
      if locked?
        halt 423, locked? # halt_on_lock helper?
      else
        File.open(LOCK_FILE, 'w') { |f| f.write "Currently printing" }
      end

      stl_url  = params[:url]
      stl_file = 'data/print.stl'
      PrintMe::Download.new(stl_url, stl_file).fetch
      makefile = File.join(File.dirname(__FILE__), '..', 'Makefile')
      make_stl = [ "make", "#{File.dirname(stl_file)}/#{File.basename(stl_file, '.stl')};",
                   "rm #{PID_FILE}"].join(" ")

      begin
        pid = Process.spawn(make_stl, :err => :out, :out => LOG_FILE)
        File.open(PID_FILE, 'w') { |f| f.write pid }
        Timeout::timeout(5) do
          Process.wait pid
          status 500
          "Process died within 5 seconds with exit status #{$?.exitstatus}"
        end
      rescue Timeout::Error
        status 200
        "Looks like it's printing correctly"
      end
    end

    post '/kill' do
      require_basic_auth
      if File.exist?(PID_FILE)
        pid = File.open(PID_FILE, 'r') { |f| f.read }.to_i
        out = Process.kill("HUP", pid)
        File.delete(PID_FILE)
        status 200
        "Killed job, exited with status #{out}"
      else
        status 404
        "No process running"
      end
    end

    get '/log' do
      content_type :text
      File.read(LOG_FILE)
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
  end
end
