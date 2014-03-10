pavlov.specify("Omega.UI.CommandTracker", function(){
describe("Omega.UI.CommandTracker", function(){
  describe("callbacks", function(){
    describe("#construction_complete", function(){
      var page, tracker;
      var constructed, station, estation, eargs;

      before(function(){
        sinon.stub(Omega.Ship, 'get');

        page = new Omega.Pages.Test({canvas : Omega.Test.Canvas()});
        sinon.stub(page, 'process_entity');
        sinon.stub(page.canvas, 'add');
        sinon.stub(page.canvas, 'reload');
        sinon.stub(page.canvas.entity_container, 'refresh');

        page.audio_controls = new Omega.UI.AudioControls({page: page});
        page.audio_controls.disabled = true;

        tracker = new Omega.UI.CommandTracker({page : page});

        var system = new Omega.SolarSystem({id : 'sys1'});
        page.canvas.set_scene_root(system);

        constructed = Omega.Gen.ship({id : 'constructed_ship' });
        station     = Omega.Gen.station({id : 'station1',
                                         system_id : 'sys1',
                                         construction_percent: 0.4});
        estation    = Omega.Gen.station({id  : 'station1', 
                                         system_id : 'sys1',
                                         resources : [{'material_id' : 'gold'}]});

        page.entities = [station, constructed];
        eargs         = ['construction_complete', estation, constructed];
      });

      after(function(){
        Omega.Ship.get.restore();
        page.canvas.add.restore();
        page.canvas.reload.restore();
        page.canvas.entity_container.refresh.restore();
      });

      it("sets station construction percent to 0", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        assert(station.construction_percent).equals(0);
      });

      it("updates station resources", function(){
        sinon.spy(station, '_update_resources');
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        sinon.assert.called(station._update_resources);
        assert(estation.resources).isSameAs(estation.resources)
      });

      it("reloads station in scene", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(page.canvas.reload,
                                station, sinon.match.func);
      });

      it("retrieves constructed entity", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(Omega.Ship.get,
          'constructed_ship', page.node, sinon.match.func);
      });

      it("processes constructed entity", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        var retrieved = new Omega.Ship();
        Omega.Ship.get.omega_callback()(retrieved);
        sinon.assert.calledWith(page.process_entity, retrieved);
      });

      it("plays construction audio effect", function(){
        sinon.stub(page.audio_controls, 'play');
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);

        var retrieved = new Omega.Ship({system_id : 'sys1'});
        station.construction_audio = 'audio';

        Omega.Ship.get.omega_callback()(retrieved);
        sinon.assert.calledWith(page.audio_controls.play,
                                station.construction_audio);
      });

      it("adds constructed entity to canvas scene", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        var retrieved = new Omega.Ship({system_id : 'sys1'});
        Omega.Ship.get.omega_callback()(retrieved);
        sinon.assert.calledWith(page.canvas.add, retrieved);
      });

      it("refreshes the entity container", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        sinon.assert.called(page.canvas.entity_container.refresh);
      });
    });
  });
});});
