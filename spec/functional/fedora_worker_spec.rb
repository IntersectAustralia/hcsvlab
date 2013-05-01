require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'activemessaging/test_helper'
require File.dirname(__FILE__) + '/../../app/processors/application_processor'

describe FedoraWorker do
  
  include ActiveMessaging::TestHelper
  
  before(:each) do
    load File.dirname(__FILE__) + "/../../app/processors/fedora_worker.rb"
    @processor = FedoraWorker.new
  end
  
  after(:each) do
    @processor = nil
  end
  
  it "should receive message" do
    @processor.on_message('Your test message here!')
  end

  
  
end