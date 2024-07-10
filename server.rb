# frozen_string_literal: true

require "socket"
require "json"
require "securerandom"
require_relative "request_handler/base"
require_relative "request_handler/completions"
require_relative "request_handler/models"

def handle_request(request)
  method, path, = request.lines[0].split
  puts "handle_request #{method} #{path}"

  case [method, path]
  when ["GET", "/v1/models"]
    handler = RequestHandler::Models.new
  when ["POST", "/v1/chat/completions"]
    handler = RequestHandler::Completions.new
  else
    return ["Not Found", "404 Not Found", false]
  end
  handler.handle_request(request)
rescue StandardError => e
  [e.message, "500 Internal Server Error", false]
end

server = TCPServer.new(12_345)
loop do
  client = server.accept
  request = client.readpartial(2048)
  body, status, stream = handle_request(request)

  if stream
    client.print "HTTP/1.1 #{status}\r\n" \
                   "Content-Type: text/event-stream\r\n" \
                   "Connection: close\r\n"

    client.print "\r\n"
    body.call(client)
  else
    client.print "HTTP/1.1 #{status}\r\n" \
                   "Content-Type: application/json\r\n" \
                   "Content-Length: #{body.bytesize}\r\n" \
                   "Connection: close\r\n"

    client.print "\r\n"
    client.print body
  end

  client.close
end
