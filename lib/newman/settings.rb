module Newman 
  class Settings
    def self.from_file(filename)
      new.tap { |o| o.load_config(filename) }
    end
  
    def initialize
      self.imap        = OpenStruct.new
      self.smtp        = OpenStruct.new
      self.service     = OpenStruct.new
      self.application = OpenStruct.new
    end

    def load_config(filename)
      eval(File.read(filename), binding)
    end

    def to_s
      {}.tap do |hash| 
        [:imap, :smtp, :service, :application].each do |key|
          hash[key] = self.send(key).marshal_dump
        end
      end
    end

    attr_accessor :imap, :smtp, :service, :application
  end
end
