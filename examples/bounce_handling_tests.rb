require_relative "example_helper"
require "minitest/autorun"

server = Newman::Server
server.test_mode("config/test.rb")

mailer = server.mailer


describe "simple bounce handling" do

  before do
    @app = Newman::Application.new do
      bounced { respond(:subject => 'bounced!') }
      default { respond(:subject => 'not bounced!') }
    end
  end
  
  it "responds to bounced email" do
    mailer.deliver_message(:to => 'test+bounce@test.com',
                           :subject => 'Failure Notice')
    server.tick(@app)
    mailer.messages.first.subject.must_equal('bounced!')
  end
  
  it "responds to regular email" do
    mailer.deliver_message(:to => 'test+bounce@test.com',
                           :subject => 'hello')
    server.tick(@app)
    mailer.messages.first.subject.must_equal('not bounced!')
  end
  
end

describe "bounce handling by type" do

  before do
    @app = Newman::Application.new do
      bounced(:type, 'Permanent Failure') do 
        respond(:subject => 'hard bounced!') 
      end
      bounced(:type, 'Persistent Transient Failure') do 
        respond(:subject => 'soft bounced!') 
      end
        
      default do
        respond(:subject => 'not handled!')
      end
    end
  end

  it "responds to soft bounced email" do
    mailer.deliver_message(:to => 'test+bounce@test.com',
                           :body => 'Mail rejected: User mailbox exceeds allowed size')
    server.tick(@app)
    mailer.messages.first.subject.must_equal('soft bounced!')   
  end
  
  it "responds to hard bounced email" do
    mailer.deliver_message(:to => 'test+bounce@test.com',
                           :body => 'Mail rejected: User unknown')
    server.tick(@app)
    mailer.messages.first.subject.must_equal('hard bounced!')
  end
  
  it "responds to regular email" do
    mailer.deliver_message(:to => 'test+bounce@test.com',
                           :subject => 'hello')
    server.tick(@app)
    mailer.messages.first.subject.must_equal('not handled!')
  end
  
end

describe "bounce handling by code" do

  before do
    @app = Newman::Application.new do
      bounced(:code, '99') do 
        respond(:subject => 'autoreply!') 
      end
      bounced(:code, '4.2.2') do 
        respond(:subject => 'mailbox full!') 
      end
        
      default do
        respond(:subject => 'not handled!')
      end
    end
  end
  
  it "responds to vacation auto-reply (code 99)" do
    mailer.deliver_message(:to => 'test+bounce@test.com',
                           :subject => 'Out of office')
    server.tick(@app)
    mailer.messages.first.subject.must_equal('autoreply!')   
  end
  
  it "responds to mailbox full (code 4.2.2)" do
    mailer.deliver_message(:to => 'test+bounce@test.com',
                           :body => 'mailbox is over quota')
    server.tick(@app)
    mailer.messages.first.subject.must_equal('mailbox full!')
  end
  
  it "responds to regular email" do
    mailer.deliver_message(:to => 'test+bounce@test.com',
                           :subject => 'hello')
    server.tick(@app)
    mailer.messages.first.subject.must_equal('not handled!')
  end

end


#TODO: bounce handling by reason
