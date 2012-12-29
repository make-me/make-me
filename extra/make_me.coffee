# Hubot script to control make-me/make-me
#
# Print a thing on the MakerBot 3D printer using the
# https://github.com/make-me/make-me
#
# 3d? - Give a basic overview of how to print
#
# 3d me <stl file URL> - Connect to the 3d printer and attempt to print the stl
# file with default settings.
#
# 3d snapshot|status - Grabs a picture of the 3d printer and tells you if it's
# locked
#
# 3d unlock me - Unlocks the 3d printer once you've cleaned off your print
#
util = require 'util'
qs = require 'querystring'

makeServer = 'http://localhost:9393'
[authUser, authPass] = ['hubot', 'isalive']
auth64 = (new Buffer("#{authUser}:#{authPass}")).toString("base64")

module.exports = (robot) ->
  robot.respond /3d\??$/i, (msg) ->
    response = "#{robot.name} 3d me [STL URLs] [[options]] - prints an STL file\n" +
               "  You can list multiple URLs separated by spaces.\n" +
               "\n" +
               "  Options can follow the URL and are:\n" +
               "    '(high|medium|low) quality' -- sets the quality of the print. Default: medium\n" +
               "    'xN' (e.g. x2)              -- print more than one of a thing at once\n" +
               "    'with supports'             -- adds supports to the model, for complex overhangs. Default: disabled\n" +
               "    'xx% solid'                 -- changes how solid the object is on the inside. Default: 5%\n" +
               "    'scale by X.Y' (e.g. 0.5)   -- scale the size of the model by a factor
               "#{robot.name} 3d snapshot - takes a picture and tells you the locked status\n" +
               "#{robot.name} 3d unlock - unlocks the printer after you clean up\n\n" +
               "Only 1 print at a time is allowed, and you are required to tell\n" +
               "#{robot.name} after you've cleaned your print off.\n\n" +
               "The most current log is always available at #{makeServer}/log"
    msg.send response

  robot.respond /3d (snapshot|status)/i, (msg) ->
    locked_msg = "unlocked"
    msg.http(makeServer + "/lock")
      .header("Authorization", "Basic #{auth64}")
      .get() (err, res, body) =>
        if res.statusCode is 423
          locked_msg = "locked"
    msg.http(makeServer).scope('photo')
      .get() (err, res, body) =>
        if res.statusCode is 302
          msg.reply "I can't see anything, what does it look like to you? I hear the machine is #{locked_msg}."
          msg.send res.headers.location
        else
          msg.reply "I can't seem to get a hold of a picture for you, but the internets tell me the machine is #{locked_msg}."

  robot.respond /3d unlock( me)?/i, (msg) ->
    msg.http(makeServer + "/lock")
      .header("Authorization", "Basic #{auth64}")
      .post(qs.encode({"_method": "DELETE"})) (err, res, body) =>
        if res.statusCode is 200
          msg.reply "Oh you finally decided to clean up?"
        else if res.statusCode is 404
          msg.reply "There's no lock. Go print something awesome!"
        else
          msg.reply "Unexpected status code #{res.statusCode}!"
          msg.reply body

  robot.respond /(3d|make)( me)?( a)? (http[^\s]+)\s*(.*)/i, (msg) ->
    things = [msg.match[4]]
    count = 1
    scale = 1.0
    config = 'default'
    quality = 'medium'
    density = 0.05
    options = msg.match[5]

    # Extract any extra urls
    while url = /(http[^\s]+)\s?/.exec(options)
      things.push url[1]
      options = options.slice(url[1].length + 1)

    if count_op = /x(\d+)/.exec(options)
      count = parseInt(count_op[1])

    if /with support/.exec(options)
      config = 'support'

    if quality_op = /(\w+) quality/.exec(options)
      quality = quality_op[1]

    if density_op = /(\d+)% solid/.exec(options)
      density = parseFloat(density_op[1]) / 100.0

    if scale_op = /scale by (\d+\.\d+)/.exec(options)
      scale = parseFloat(scale_op[1])

    msg.reply "Talking to the 3d printer to print #{things.length} models '#{options}'..."
    msg.http(makeServer + "/print")
      .header("Authorization", "Basic #{auth64}")
      .post(JSON.stringify({url: things, count: count, scale: scale, quality: quality, density: density, config: config})) (err, res, body) =>
        if res.statusCode is 200
          msg.reply "Your thing is printin'! Check logs at #{makeServer}/log"
        else if res.statusCode is 409
          msg.reply "I couldn't process that pile of triangles."
        else if res.statusCode is 423
          msg.reply "Wait your turn, someone is already printing a thing. You can check progress at #{makeServer}/log"
        else if err or res.statusCode is 500
          msg.reply "Something broke!"
