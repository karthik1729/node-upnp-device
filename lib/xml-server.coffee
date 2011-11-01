http = require 'http'
fs = require 'fs'
url = require 'url'
portscanner = require 'portscanner'
device = require './device'
helpers = require './helpers'

exports.start = (config, callback) ->
    
    server = http.createServer (request, response) ->
        # url formats:
        # /device/description
        # /service/(description|control|event)/serviceType
        path = url.parse(request.url).pathname.split('/')
        reqType = path[1]
        action = path[2]
        serviceType = path[3]

        if reqType in ['device', 'service']
            response.writeHead 200, 'Content-Type': 'text/xml'
            # service descriptions are static files
            if reqType is 'service' and action is 'description'
                fs.readFile __dirname + '/services/' + serviceType + '.xml', (err, file) ->
                    throw err if err
                    response.write file
                    response.end()
            else
                response.write '<?xml version="1.0" encoding="utf-8"?>\n'
                if reqType is 'device'
                    response.write device.buildDescription config
                response.end()
        else
            response.writeHead 404, 'Content-Type': 'text/plain'
            response.write '404 Not found'
            response.end()

    # find internal address and port to use for http server
    helpers.getNetworkIP (err, address) ->
        throw err if err
        portscanner.findAPortNotInUse 49201, 49220, address, (err, port) ->
            throw err if err
            server.listen port, address, ->
                console.log "Web server listening on #{address}:#{port}"
                callback null, { port: port, address: address }
