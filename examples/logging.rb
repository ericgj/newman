require 'logger'
require_relative "example_helper"

module Newman
  module Examples

    module Logger
      def logger(io=nil, *args, &config)
        if io
          @logger = ::Logger.new(io, *args)
        else
          @logger ||= logger(STDERR)
        end
        block_given? ? @logger.tap(&config) : @logger
      end
    end
    
    # for lack of a controller plugin model, this ugliness..
    # could we simply put logger method directly in Controller instead,
    # it's probably generally useful to have it for many callbacks
    Newman::Controller.send(:include, Logger)
    
    RequestLogger = Newman::Application.new do
      default do
        # mail.to_s returns the entire email as a string
        # perhaps instead it should log a one-line summary at :info level,
        # and the whole email at :debug level
        logger.info "REQUEST:\n #{request}"
      end      
    end
    
    ResponseLogger = Newman::Application.new do
      default do
        logger.info "RESPONSE:\n #{response}"
      end
    end
    
    Echo = Newman::Application.new do
      default do
        response.subject = "You said #{request.subject}"
      end
    end
    
  end
end


if __FILE__ == $PROGRAM_NAME
  Newman::Server.simple( [ Newman::Examples::RequestLogger,
                           Newman::Examples::Echo,
                           Newman::Examples::ResponseLogger
                         ], 
                         "config/environment.rb"
                       )
end