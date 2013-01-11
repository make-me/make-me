#!/usr/bin/env ruby

require 'bundler'
Bundler.require
require 'timeout'
require_relative 'lib/download'
require_relative 'lib/normalizer'
require_relative 'lib/miracle_grue_configurator'

module MakeMe
  class App < Sinatra::Base
    RACK_ROOT          = ENV['RACK_ROOT']
    PID_FILE           = File.join(RACK_ROOT, 'tmp', 'make.pid')
    LOG_FILE           = File.join(RACK_ROOT, 'tmp', 'make.log')
    FETCH_MODEL_FILE   = File.join(RACK_ROOT, 'data', 'fetch.stl')
    CURRENT_MODEL_FILE = File.join(RACK_ROOT, 'data', 'print.stl')
    GRUE_CONFIG        = File.join(RACK_ROOT, 'config', 'grue-make-me.config')

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
      @current_log = File.read(LOG_FILE) if File.exists?(LOG_FILE)
      erb :index
    end

    get '/about' do
      erb :about
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
      imagesnap = File.join(RACK_ROOT, 'vendor', 'imagesnap', 'imagesnap')
      out_name = 'snap_' + Time.now.to_i.to_s + ".jpg"
      out_dir = settings.public_folder

      # Ask for the all the cameras we have
      # the first line is a header.
      cameras = IO.popen([imagesnap, "-l"]) do |cameras|
        cameras.readlines
      end[1..-1]

      # Pick one safely and use it
      camera = cameras[params[:camera].to_i % cameras.length].strip
      Process.wait Process.spawn(*[imagesnap, '-d', camera, File.join(out_dir, out_name)])

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

      args = Yajl::Parser.new(:symbolize_keys => true).parse(request.body.read) || {}

      stl_urls    = [*args[:url]]
      count       = args[:count]
      scale       = args[:scale]
      slicer_args = (args[:slicer_args] || {})
      quality     = (args[:quality]  || 'medium')

      normalizer_args = {}
      normalizer_args[:count] = count if count
      normalizer_args[:scale] = scale if scale

      line_height = case quality
                    when 'low'
                      0.34
                    when 'high'
                      0.1
                    else
                      0.27
                    end

      # Merge slicer_args into the quality array. Anything in slicer_args
      # overwrites our notion of "quality"
      slicer_args = {:lineHeight => line_height}.merge(slicer_args)

      configurator = MakeMe::MiracleGrueConfigurator.new(slicer_args)
      configurator.save(GRUE_CONFIG)

      # Fetch all of the inputs to temp files
      inputs = MakeMe::Download.new(stl_urls, FETCH_MODEL_FILE).fetch

      output = CURRENT_MODEL_FILE
      normalizer = MakeMe::Normalizer.new(inputs, output, normalizer_args)
      unless normalizer.normalize!
        halt 409, "Normalizing model failed"
      end

      # Print the normalized STL
      make_stl    = [ "make", "GRUE_CONFIG=make-me",
                      "#{File.dirname(output)}/#{File.basename(output, '.stl')};",
                      "rm #{PID_FILE}"].join(" ")

      # Slicing usually is usually under 5 seconds, so if the process runs
      # longer, it's probably printing correctly
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

    get '/log' do
      content_type :text
      File.read(LOG_FILE) if File.exists?(LOG_FILE)
    end
  end
end

require_relative 'app/lock'
