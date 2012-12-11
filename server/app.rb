#!/usr/bin/env ruby

require 'bundler'
Bundler.require
require 'timeout'
require_relative 'lib/download'

module PrintMe
  class App < Sinatra::Base
    PID_FILE  = File.join('tmp', 'make.pid')
    LOG_FILE  = File.join('tmp', 'make.log')
    CURRENT_MODEL_FILE = File.join('data', 'print.stl')

    ## Config
    set :static, true

    basic_auth do
      realm 'The 3rd Dimension'
      username ENV['MAKE_ME_USERNAME'] || 'hubot'
      password ENV['MAKE_ME_PASSWORD'] || 'isalive'
    end

    def progress
      progress = 0
      if File.exists?(LOG_FILE)
        File.readlines(LOG_FILE).each do |line|
          matches = line.strip.scan /Sent \d+\/\d+ \[(\d+)%\]/
          matches.length > 0 && progress = matches[0][0].to_i
        end
      end
      progress
    end

    ## Routes/Public
    get '/' do
      @is_locked = locked?
      begin
        @current_log = File.read(LOG_FILE) if File.exists?(LOG_FILE)
      rescue Errno::ENOENT
      end
      @progress = progress
      erb :index
    end

    get '/current_model' do
      if File.exist?(CURRENT_MODEL_FILE)
        content_type "application/sla"
        send_file CURRENT_MODEL_FILE
      else
        status 404
        "not found"
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
        lock!
      end

      stl_url  = params[:url]
      stl_file = CURRENT_MODEL_FILE
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
      File.read(LOG_FILE) if File.exists?(LOG_FILE)
    end
  end
end

require_relative 'app/lock_file'
