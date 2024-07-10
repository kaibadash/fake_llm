# frozen_string_literal: true

module RequestHandler
  class Models < RequestHandler::Base
    def handle_request(_request)
      response = {
        data: [
          { id: "fake_llm", object: "model", created: Time.now.to_i, owned_by: "fake_llm" },
        ],
      }
      [response.to_json, "200 OK", false]
    end
  end
end
