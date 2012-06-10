# jump_gate module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Cosmos::JumpGate do

  it "should successfully accept and set jump_gate params" do
     system      = Cosmos::SolarSystem.new
     endpoint    = Cosmos::SolarSystem.new
     jump_gate   = Cosmos::JumpGate.new :solar_system => system, :endpoint => endpoint
     jump_gate.location.should_not be_nil
     jump_gate.location.x.should == 0
     jump_gate.location.y.should == 0
     jump_gate.location.z.should == 0
     jump_gate.solar_system.should == system
     jump_gate.endpoint.should == endpoint
     jump_gate.has_children?.should be_false
  end

  it "should be not able to be remotely trackable" do
    Cosmos::JumpGate.remotely_trackable?.should be_false
  end

  it "should be convertable to json" do
     system      = Cosmos::SolarSystem.new
     endpoint    = Cosmos::SolarSystem.new
    g = Cosmos::JumpGate.new(:solar_system => system, :endpoint => endpoint,
                             :location => Motel::Location.new(:x => 50))
    j = g.to_json
    j.should include('"json_class":"Cosmos::JumpGate"')
    j.should include('"json_class":"Motel::Location"')
    j.should include('"x":50')
  end

  it "should be convertable from json" do
    j = '{"data":{"solar_system":null,"endpoint":null,"location":{"data":{"parent_id":null,"z":null,"restrict_view":true,"x":50,"restrict_modify":true,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"id":null,"remote_queue":null,"y":null},"json_class":"Motel::Location"}},"json_class":"Cosmos::JumpGate"}'
    g = JSON.parse(j)

    g.class.should == Cosmos::JumpGate
    g.location.x.should  == 50
  end

end