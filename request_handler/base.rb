# frozen_string_literal: true

module RequestHandler
  class Base
    def handle_request(_request)
      raise NotImplementedError, "Subclasses must implement the handle_request method"
    end
  end
end
