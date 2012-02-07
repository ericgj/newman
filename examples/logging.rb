require_relative "example_helper"

module Newman
  module Examples
    
    class Logger
        
      attr_accessor :logger,   :log_request, :log_response,
                    :settings, :request,     :response
      
      def initialize(logger, opts={})
        self.logger = logger
        self.log_request =  !!opts[:log_request]
        self.log_response = !!opts[:log_response]
      end
      
      def call(params)
        self.settings = params.fetch(:settings)
        self.request  = params.fetch(:request)
        self.response = params.fetch(:response)
        
        log_email("REQUEST", request)   if log_request
        log_email("RESPONSE", response) if log_response
      end
      
      def log_email(prefix, email)
        logger.debug('SETTINGS') { settings  }
        logger.debug(prefix)     { "\n#{email}"   }
        logger.info(prefix)      { summary(email) }
      end
      
      def summary(email)
        {}.tap do |hash|
          %w[from to bcc subject reply_to].each do |fld| 
            hash[fld] = email.send(fld)
          end
        end
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

  require 'logger'
  logger = ::Logger.new(STDERR)
  logger.level = ::Logger::Severity::DEBUG
  
  Newman::Server.simple( 
    [ Newman::Examples::Logger.new(logger, :log_request  => true),
      Newman::Examples::Echo,
      Newman::Examples::Logger.new(logger, :log_response => true)
    ], 
    "config/environment.rb"
  )
  
end