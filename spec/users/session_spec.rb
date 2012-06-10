# session module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Users::Session do

  it "should properly initialze session" do
    id = Motel.gen_uuid
    s = Users::Session.new :id => id, :user_id => 'user1'
    s.id.should == id
    s.user_id.should == 'user1'
    s.login_time.should_not be_nil
  end

  it "should be convertable to json" do
    id = '1234'
    s = Users::Session.new :id => id, :user_id => 'user1'

    j = s.to_json
    j.should include('"json_class":"Users::Session"')
    j.should include('"id":"'+id+'"')
    j.should include('"user_id":"user1"')
    j.should include('"login_time":')
  end

  it "should be convertable from json" do
    j = '{"data":{"login_time":"Wed Mar 28 16:23:02 -0400 2012","id":"1234","user_id":"user1"},"json_class":"Users::Session"}'
    s = JSON.parse(j)

    s.class.should == Users::Session
    s.id.should == "1234"
    s.user_id.should == 'user1'
    s.login_time.should_not be_nil
  end

end