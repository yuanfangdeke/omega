# Omega Server Registry HasEntities Mixin tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'ostruct'
require 'spec_helper'

# test through registry inclusion
require 'omega/server/registry'

module Omega
module Server
module Registry
  describe HasEntities do
    before(:each) do
      @registry = Object.new
      @registry.extend(Registry)

      @obj1 = { 'foo' => 'bar' }
      @obj2 = { 'bar' => 'foo' }
      @obj3 = { 'oof' => 'ah' }
    end

    describe "#entities" do
      it "returns all entities" do
        @registry << @obj1
        @registry << @obj2
        @registry.entities.should == [@obj1, @obj2]
      end

      it "returns entities matching criteria" do
        @registry << @obj1
        @registry << @obj2
        @registry.entities { |e| e.has_key?('foo') }.should == [@obj1]
      end

      it "returns the copies of entities" do
        @registry << @obj1
        e = @registry.entities

        # test values are same but objects are not
        e.first.should == @obj1
        e.first.should_not equal(@obj1)
      end

      it "invokes retrieval on each entity" do
        @registry << @obj1
        @registry << @obj2

        @registry.retrieval.should_receive(:call).with(@obj1)
        @registry.retrieval.should_receive(:call).with(@obj2)
        e = @registry.entities
      end
    end

    describe "#entity" do
      it "returns first matching result" do
        @registry << @obj1
        @registry << @obj2
        @registry << @obj3
        selector = proc { |e| e.object_id ==  @obj2.object_id }
        v = @registry.entity &selector
        v.should == @obj2
      end
    end

    describe "#clear!" do
      it "empties entities list" do
        @registry << @obj1
        @registry << @obj2
        @registry.clear!
        @registry.entities.should be_empty
      end
    end

    describe "#<<" do
      before(:each) do
        @added = nil
        @registry.on(:added) { |e| @added = e }
      end

      context "validation not set" do
        it "adds entity" do
          @registry << @obj1
          @registry << @obj1
          @registry.entities.should == [@obj1, @obj1]
        end

        it "returns true" do
          @registry.<<(@obj1).should be_true
          @registry.<<(@obj1).should be_true
        end

        it "raises added event" do
          @registry << @obj1
          @added.should == @obj1

          @registry << @obj2
          @added.should == @obj2

          @registry << @obj1
          @added.should == @obj1
        end
      end

      context "validation is set" do
        before(:each) do
          @registry.validation_callback { |entities, e|
            !entities.include?(e)
          }
        end

        context "validation passes" do
          it "adds entity" do
            @registry << @obj1
            @registry << @obj2
            @registry.entities.should == [@obj1,@obj2]
          end

          it "returns true" do
            @registry.<<(@obj1).should be_true
            @registry.<<(@obj2).should be_true
          end

          it "raises added event" do
            @registry << @obj1
            @added.should == @obj1

            @registry << @obj2
            @added.should == @obj2
          end
        end

        context "validation fails" do
          it "doesn't add the entity" do
            @registry << @obj1
            @registry << @obj1
            @registry.entities.should == [@obj1]
          end

          it "returns false" do
            @registry.<<(@obj1).should be_true
            @registry.<<(@obj1).should be_false
          end

          it "doesn't raise added event" do
            @registry << @obj1
            @added.should == @obj1

            @registry << @obj2
            @added.should == @obj2

            @registry << @obj1
            @added.should == @obj2
          end
        end
      end

      context "multiple validations are set" do
        before(:each) do
          @first = true
          @second = true
          @registry.validation_callback { |entities, e|
            @first
          }
          @registry.validation_callback { |entities, e|
            @second
          }
        end

        context "all validations passes" do
          it "adds entity" do
            @registry << @obj1
            @registry.entities.should == [@obj1]
          end

          it "returns true" do
            @registry.<<(@obj1).should be_true
          end

          it "raises added event" do
            @registry << @obj1
            @added.should == @obj1
          end
        end

        context "one or more validations fail" do
          before(:each) do
            @second = false
          end

          it "doesn't add the entity" do
            @registry << @obj1
            @registry.entities.should == []
          end

          it "returns false" do
            @registry.<<(@obj1).should be_false
          end

          it "doesn't raise added event" do
            @registry << @obj1
            @added.should be_nil
          end
        end
      end
    end

    describe "#delete" do
      it "deletes first entity matching selector" do
        @registry << @obj1
        @registry << @obj2
        @registry << @obj3
        @registry.delete { |e| e.object_id == @obj3.object_id }
        @registry.entities.should include(@obj1)
        @registry.entities.should include(@obj2)
        @registry.entities.should_not include(@obj3)
      end

      context "entity deleted" do
        it "raises :deleted event" do
          @registry << @obj1
          @registry.should_receive(:raise_event).with(:deleted, @obj1)
          @registry.delete
        end

        it "returns true" do
          @registry << @obj1
          @registry.delete.should be_true
        end
      end

      context "entity not deleted" do
        it "does not raise :deleted event" do
          @registry.should_not_receive(:raise_event)
          @registry.delete { |e| false }
        end

        it "returns false" do
          @registry.delete { |e| false }.should be_false
        end
      end
    end

    describe "#update" do
      before(:each) do
        # primary entities (first two will be stored)
        @e1  = OmegaTest::ServerEntity.new(:id => 1, :val => 'a')
        @e2  = OmegaTest::ServerEntity.new(:id => 2, :val => 'b')
        @e3  = OmegaTest::ServerEntity.new(:id => 3, :val => 'c')

        # create an copy of e2/e3 which we will not modify (for validation)
        @orig_e2  = OmegaTest::ServerEntity.new(:id => 2, :val => 'b')
        @orig_e3  = OmegaTest::ServerEntity.new(:id => 3, :val => 'c')

        # create entities to use to update
        @e2a = OmegaTest::ServerEntity.new(:id => 2, :val => 'd')
        @e3a = OmegaTest::ServerEntity.new(:id => 3, :val => 'e')

        # define a selector which to use to select entities
        @select_e2 = proc { |e| e.id == @e2.id }
        @select_e3 = proc { |e| e.id == @e3.id }

        # update requires 'update' method on entities
        [@e1, @e2, @e3].each { |e|
          e.eigenclass.send(:define_method, :update,
                      proc { |v| self.val = v.val })
        }

        # add entities to registry
        @registry << @e1
        @registry << @e2

        # handle updated event
        @updated_n = @updated_o = nil
        @registry.on(:updated) { |n,o| @updated_n = n ; @updated_o = o }
      end

      context "selected entity found" do
        it "updates entity" do
          @registry.update(@e2a, &@select_e2)
          @e2.should == @e2a
        end

        it "raises updated event" do
          @registry.update(@e2a, &@select_e2)
          @updated_n.should == @e2a
          @updated_o.should == @orig_e2
        end

        it "returns true" do
          @registry.update(@e2a, &@select_e2).should == true
        end
      end

      context "selected entity not found" do
        it "does not update entity" do
          @registry.update(@e3a, &@select_e3)
          @e3.should == @orig_e3
        end

        it "does not raise updated event" do
          @registry.update(@e3a, &@select_e3)
          @updated_n.should be_nil
          @updated_o.should be_nil
        end

        it "returns false" do
          @registry.update(@e3a, &@select_e3).should be_false
        end
      end
    end
  end # describe HasEntities
end # module Registry
end # module Server
end # module Omega
