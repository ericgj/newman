module Newman  
  class Server
    def self.test_mode(settings_file)
      settings = Settings.from_file(settings_file)
      mailer   = TestMailer.new(settings)

      new(settings, mailer)
    end

    def self.simple(app, settings_file)
      settings = Settings.from_file(settings_file)
      mailer   = Mailer.new(settings)

      server = new(settings, mailer)

      server.run(app)
    end

    def initialize(settings, mailer)
      self.settings = settings
      self.mailer   = mailer
    end

    attr_accessor :settings, :mailer

    def run(apps)
      loop do
        tick(apps)
        sleep settings.service.polling_interval
      end
    end

    def tick(apps)           
      mailer.messages.each do |request|
      
        response = mailer.new_message(:to   => request.from, 
                                      :from => settings.service.default_sender)
        Array(apps).each do |app|
          
          begin
            app.call(:request  => request, 
                     :response => response, 
                     :settings => settings)
          rescue StandardError => e
            debug("ERROR: #{e.inspect}\n"+e.backtrace.join("\n  "))

            if settings.service.raise_exceptions
              raise
            else
              next    # next app
              # alternatively, break and go to next message without delivery
              #   response.perform_deliveries = false
              #   break
            end
          end

        end
        
        response.deliver
        
      end
    end


    private

    def debug(message)
      STDERR.puts("#{message}\n\n") if settings.service.debug_mode || $DEBUG
    end
  end
end
