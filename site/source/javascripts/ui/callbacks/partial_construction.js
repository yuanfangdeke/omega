/* Omega JS Partial Construction Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.partial_construction = function(event, evnt_args){
  var station           = evnt_args[1];
  var being_constructed = evnt_args[2];
  var percent           = evnt_args[3];

  var pstation = $.grep(this.page.all_entities(),
                        function(entity){ return entity.id == station.id; })[0];

  pstation._constructing = true;
  pstation.construction_percent = percent;
  if(this.page.canvas.is_root(pstation.parent_id)){
    this.page.canvas.reload(pstation, function(){
      pstation.update_construction_gfx();
    });
    this.page.canvas.animate();
  }
};
