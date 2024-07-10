# frozen_string_literal: true

module RequestHandler
  class Completions < RequestHandler::Base
    def generate_streaming_responses(params)
      response = generate_response_message(params)
      response.chars.map do |c|
        { content: c, finish_reason: nil, index: 0, logprobs: nil, role: "assistant" }
      end
    end

    def stream_responses(client, params)
      responses = generate_streaming_responses(params)

      responses.each do |choice|
        chunk = {
          id: "fake-llm-#{SecureRandom.uuid}",
          object: "chat.completion.chunk",
          created: Time.now.to_i,
          model: "fake_llm",
          choices: [
            {
              delta: { content: choice[:content], role: choice[:role] },
              finish_reason: choice[:finish_reason],
              index: choice[:index],
              logprobs: choice[:logprobs],
            },
          ],
        }
        client.print "data: #{chunk.to_json}\n\n"
        client.flush

        # Sometimes slow
        sleep [0, 0.001, 0.002, 0.003, 0.004, 0.1].sample
      end
    end

    def handle_request(request)
      body = request.split("\r\n\r\n", 2).last
      params = JSON.parse(body, symbolize_names: true)
      stream = params[:stream] || true
      response_format = params[:response_format] || "text"

      if stream
        response_stream = proc { |client| stream_responses(client, params) }
        return [response_stream, "200 OK", true]
      end

      message = generate_response_message(params)
      prompt_tokens = params[:messages].size * 1.5
      completion_tokens = message.size * 1.5
      response = {
        id: "fake-llm-#{SecureRandom.uuid}",
        object: "text_completion",
        created: Time.now.to_i,
        model: params[:model],
        choices: [
          { text: message, index: 0, logprobs: nil, finish_reason: "length" },
        ],
        usage: { prompt_tokens:, completion_tokens:,
                 total_tokens: prompt_tokens + completion_tokens },
      }

      return response[:choices].first[:text], "200 OK", false if response_format == "text"

      [response.to_json, "200 OK", false]
    end

    private

    def generate_response_message(params)
      "This is a fake response. Your request is...\n```#{JSON.pretty_generate(params[:messages])}```"
    end
  end
end
