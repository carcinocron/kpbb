class HTTP::Server::Response
  class Output
    # original definition since Crystal 0.35.0
    def close
      return if closed?

      unless response.wrote_headers?
        response.content_length = @out_count
      end

      ensure_headers_written

      super

      if @chunked
        @io << "0\r\n\r\n"
        @io.flush
      end
    end

    # patch from https://github.com/kemalcr/kemal/pull/576
    def close
      # ameba:disable Style/NegatedConditionsInUnless
      unless response.wrote_headers? && !response.headers.has_key?("Content-Range")
        response.content_length = @out_count
      end

      ensure_headers_written

      previous_def
    end
  end
end
