# manufactured::move entity_in_system helper specs
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

# TODO split tests out into ship / station in_system modules

require 'spec_helper'
require 'manufactured/rjr/move/entity_in_system'

module Manufactured::RJR
  describe "#move_entity_in_system", :rjr => true do
    include Omega::Server::DSL # for with_id below
    include Manufactured::RJR

    before(:each) do
      setup_manufactured :MOVE_METHODS

      @sys  = create(:solar_system)
      @rsys = Cosmos::RJR.registry.safe_exec { |es| es.find &with_id(@sys.id) }

      @l   = build(:location, :coordinates => [0,0,0])
      @sh  = create(:valid_ship,
                    :solar_system => @sys,
                    :location => build(:location,
                                       :coordinates => [10,0,0]))
      @rsh = @registry.safe_exec { |es| es.find &with_id(@sh.id) }
    end

    context "entity is not a ship" do
      it "raises OperationError" do
        lambda {
          move_entity_in_system(create(:valid_station), @l)
        }.should raise_error(OperationError)
      end
    end

    context "ship is docked" do
      it "raises OperationError" do
        sh = create(:valid_ship, :docked_at => build(:station))
        lambda {
          move_entity_in_system(sh, @l)
        }.should raise_error(OperationError)
      end
    end

    context "ship is at location" do
      it "raises OperationError" do
        sh = create(:valid_ship, :location => @l)
        lambda {
          move_entity_in_system(sh, @l)
        }.should raise_error(OperationError)
      end
    end

    context "entity is facing destination" do
      it "moves entity towards destination" do
        @sh.location.coordinates = [100, 0, 0]
        @sh.location.orientation = [-1, 0, 0]
        move_entity_in_system(@sh, @l)
        @sh.location.movement_strategy.should be_an_instance_of(Motel::MovementStrategies::Towards)
        @sh.location.movement_strategy.target.should == @l.coordinates
        @sh.location.movement_strategy.acceleration.should == @sh.acceleration
        @sh.location.movement_strategy.max_speed.should == @sh.movement_speed
        @sh.location.movement_strategy.speed.should == 1
        @sh.location.movement_strategy.rot_theta.should == @sh.rotation_speed
      end
    end

    it "sets next movement strategy to stopped" do
      move_entity_in_system(@sh, @l)
      @sh.location.next_movement_strategy.should == Motel::MovementStrategies::Stopped.instance
    end


    it "tracks movement" do
      @sh.location.orientation = [-1, 0, 0]
      Manufactured::RJR.node.should_receive(:invoke).
                        with("motel::track_movement", @sh.id, 10.0)
      Manufactured::RJR.node.should_receive(:invoke).
                        with("motel::update_location", an_instance_of(Motel::Location))
      move_entity_in_system(@sh, @l)
    end
  end # describe #move_entity_in_system
end
