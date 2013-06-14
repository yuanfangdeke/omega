# jump_gate module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

module Cosmos
describe JumpGate do
  describe "#endpoint=" do
    it "sets endpoint" do
      s = build(:system)
      j = JumpGate.new
      j.endpoint = s
      j.endpoint.should == s
    end

    it "sets endpoint id" do
      s = build(:system)
      j = JumpGate.new
      j.endpoint = s
      j.endpoint_id.should == s.id
    end
  end

  describe "#initialize" do
    it "initializes entity" do
      args = {}
      JumpGate.any_instance.should_receive(:init_entity).with(args)
      JumpGate.new args
    end

    it "initializes system entity" do
      args = {}
      JumpGate.any_instance.should_receive(:init_system_entity).with(args)
      JumpGate.new args
    end

    it "sets defaults" do
      j = JumpGate.new
      j.endpoint_id.should be_nil
      j.endpoint.should be_nil
      j.trigger_distance.should == 100
    end

    it "sets attributes" do
      s = build(:system)
      j = JumpGate.new :endpoint => s, :trigger_distance => 50
      j.endpoint.should == s
      j.endpoint_id.should == s.id
      j.trigger_distance.should == 50
    end
  end

  describe "#valid?" do
    context "entity not valid" do
      it "returns false" do
        j = JumpGate.new
        j.should_receive(:entity_valid?).and_return(false)
        j.should_not be_valid
      end
    end

    context "system entity not valid" do
      it "returns false" do
        j = JumpGate.new
        j.should_receive(:entity_valid?).and_return(true)
        j.should_receive(:system_entity_valid?).and_return(false)
        j.should_not be_valid
      end
    end

    context "location not stopped" do
      it "returns false" do
        j = JumpGate.new
        j.should_receive(:entity_valid?).and_return(true)
        j.should_receive(:system_entity_valid?).and_return(true)
        j.location.movement_strategy = Motel::MovementStrategies::Linear.new
        j.should_not be_valid
      end
    end

    context "endpoint id not set" do
      it "returns false" do
        j = JumpGate.new
        j.should_receive(:entity_valid?).and_return(true)
        j.should_receive(:system_entity_valid?).and_return(true)
        j.endpoint_id = nil
        j.should_not be_valid
      end
    end

    context "endpoint is not a valid solar system" do
      it "returns false" do
        j = JumpGate.new
        j.should_receive(:entity_valid?).and_return(true)
        j.should_receive(:system_entity_valid?).and_return(true)
        j.endpoint.location = nil
        j.should_not be_valid
      end
    end

    context "trigger distance is invalid" do
      it "returns false" do
        j = JumpGate.new
        j.should_receive(:entity_valid?).and_return(true)
        j.should_receive(:system_entity_valid?).and_return(true)
        j.trigger_distance = 0
        j.should_not be_valid
      end
    end

    it "returns true" do
      j = JumpGate.new
      j.should_receive(:entity_valid?).and_return(true)
      j.should_receive(:system_entity_valid?).and_return(true)
      j.should be_valid
    end
  end

  describe "#to_json" do
    it "returns jump_gate in json format" do
      system      = Cosmos::SolarSystem.new
      endpoint    = Cosmos::SolarSystem.new
      g = Cosmos::JumpGate.new(:solar_system => system, :endpoint => endpoint,
                               :location => Motel::Location.new(:x => 50))
      j = g.to_json
      j.should include('"json_class":"Cosmos::JumpGate"')
      j.should include('"json_class":"Motel::Location"')
      j.should include('"x":50')
    end
  end

  describe "#json_create" do
    it "returns jump_gate from json format" do
      j = '{"data":{"solar_system":null,"endpoint":null,"location":{"data":{"parent_id":null,"z":null,"restrict_view":true,"x":50,"restrict_modify":true,"movement_strategy":{"data":{"step_delay":1},"json_class":"Motel::MovementStrategies::Stopped"},"id":null,"y":null},"json_class":"Motel::Location"}},"json_class":"Cosmos::JumpGate"}'
      g = JSON.parse(j)

      g.class.should == Cosmos::JumpGate
      g.location.x.should  == 50
    end
  end
end # describe JumpGate
end # module Cosmos
