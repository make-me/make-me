#!/usr/bin/env ruby

require 'bundler'
Bundler.require
require 'timeout'
require_relative 'lib/download'

module MakeMe
  class App < Sinatra::Base
    PID_FILE  = File.join('tmp', 'make.pid')
    LOG_FILE  = File.join('tmp', 'make.log')
    FETCH_MODEL_FILE = File.join('data', 'fetch.stl')
    CURRENT_MODEL_FILE = File.join('data', 'print.stl')

    ## Config
    set :static, true
    enable :method_override

    basic_auth do
      realm 'The 3rd Dimension'
      username ENV['MAKE_ME_USERNAME'] || 'hubot'
      password ENV['MAKE_ME_PASSWORD'] || 'isalive'
    end

    helpers do
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
    end

    get '/' do
      begin
        @current_log = File.read(LOG_FILE) if File.exists?(LOG_FILE)
      rescue Errno::ENOENT
      end
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

    ## Routes/Authed
    post '/print' do
      require_basic_auth
      if locked?
        halt 423, lock_data
      else
        lock!
      end

      # Either parse a JSON body or use params[] as usual, using the unified
      # `args' hash from here out
      begin
        jparams = Yajl::Parser.new(:symbolize_keys => true).parse request.body.read
      rescue
      end
      args = jparams || params

      stl_urls      = [*args[:url]]
      count         = (args[:count]   || 1).to_i
      scale         = (args[:scale]   || 1.0).to_f
      grue_conf     = (args[:config]  || 'default')
      slice_quality = (args[:quality] || 'medium')
      density       = (args[:density] || 0.05).to_f

      # Fetch all of the inputs to temp files
      inputs = []
      stl_urls.each_with_index do |url, index|
        stl_path = "#{FETCH_MODEL_FILE}.#{index}"
        MakeMe::Download.new(url, stl_path).fetch
        inputs.push stl_path
      end

      # Duplicate the requested number of times.
      inputs = inputs * count

      # Normalize the download
      stl_file = CURRENT_MODEL_FILE
      normalize = ['./vendor/stltwalker/stltwalker', '-p', '-o', stl_file,
                   "--scale=#{scale}", *inputs]
      pid = Process.spawn(*normalize, :err => :out, :out => [LOG_FILE, "w"])
      _pid, status = Process.wait2 pid
      halt 409, "Model normalize failed."  unless status.exitstatus == 0

      # Print the normalized STL
      make_params = [ "GRUE_CONFIG=#{grue_conf}",
                      "QUALITY=#{slice_quality}",
                      "DENSITY=#{density}"]

      make_stl    = [ "make", *make_params,
                      "#{File.dirname(stl_file)}/#{File.basename(stl_file, '.stl')};",
                      "rm #{PID_FILE}"].join(" ")

      # Kick off the print, if it runs for >5 seconds, it's unlikely it failed
      # during slicing
      begin
        pid = Process.spawn(make_stl, :err => :out, :out => [LOG_FILE, "a"])
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

require_relative 'app/lock'
