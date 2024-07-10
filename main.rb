# frozen_string_literal: true

require 'socket'
require 'json'

server = TCPServer.new 12_345

def handle_request(request)
  method, path, = request.lines[0].split

  if path == '/v1/models' && method == 'GET'
    response = {
      'data' => [
        { 'id' => 'text-davinci-003', 'object' => 'model', 'created' => 1_624_492_800, 'owned_by' => 'openai' },
        { 'id' => 'text-curie-001', 'object' => 'model', 'created' => 1_624_492_800, 'owned_by' => 'openai' }
      ]
    }
    return response.to_json, '200 OK'
  end
  if path == '/v1/completions' && method == 'POST'
    body = request.split("\r\n\r\n", 2).last
    params = JSON.parse(body)

    response_format = params['response_format'] || 'json'
    stream = params['stream'] || false

    if stream
      response_stream = proc {
        [
          { 'text' => 'This ', 'index' => 0, 'logprobs' => nil, 'finish_reason' => nil },
          { 'text' => 'is ', 'index' => 0, 'logprobs' => nil, 'finish_reason' => nil },
          { 'text' => 'a ', 'index' => 0, 'logprobs' => nil, 'finish_reason' => nil },
          { 'text' => 'fake ', 'index' => 0, 'logprobs' => nil, 'finish_reason' => nil },
          { 'text' => 'response.', 'index' => 0, 'logprobs' => nil, 'finish_reason' => 'length' }
        ].map { |choice| "data: #{choice.to_json}\n\n" }.join
      }
      return response_stream, '200 OK', true
    end
    response = {
      'id' => 'cmpl-6XsX1YXJvF6',
      'object' => 'text_completion',
      'created' => Time.now.to_i,
      'model' => params['model'],
      'choices' => [
        { 'text' => 'This is a fake response.', 'index' => 0, 'logprobs' => nil, 'finish_reason' => 'length' }
      ],
      'usage' => { 'prompt_tokens' => 5, 'completion_tokens' => 5, 'total_tokens' => 10 }
    }

    return response['choices'].first['text'], '200 OK' if response_format == 'text'

    return response.to_json, '200 OK'
  end

  ['Not Found', '404 Not Found']
end

loop do
  client = server.accept
  request = client.readpartial(2048)
  body, status, stream = handle_request(request)

  client.print "HTTP/1.1 #{status}\r\n" \
                 "Content-Type: application/json\r\n" \
                 "Content-Length: #{body.bytesize}\r\n" \
                 "Connection: close\r\n"

  client.print "\r\n"
  if stream
    body.call.each_line { |line| client.print line }
  else
    client.print body
  end
  client.close
end
