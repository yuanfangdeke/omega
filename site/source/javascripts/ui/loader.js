/* Omega JS Loader
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/jquery.storageapi-1.6.0.min"

Omega.UI.Loader = {
  placeholder : 'PLACEHOLDER',
  status_indicator : null,

  preload : function(){
    if(Omega.UI.Loader.preloaded) return;
    Omega.UI.Loader.preloaded = true;

    if(this.status_indicator)
      this.status_indicator.push_state('loading_resource');

    var config = Omega.Config;
    var event_cb = this._async_state_tracker();
    this.preload_resources(config, event_cb);
    this.preload_skybox(config, event_cb);
  },

  /// pop state when all resources finish loading
  _async_state_tracker : function(){
    var _this = this;
    this.async_events  = 0;
    this.event_counter = 0;
    return this.status_indicator ?
      function(){
        _this.event_counter += 1;
        if(_this.event_counter == _this.async_events)
          _this.status_indicator.pop_state();
      } : function(){};
  },

  _entities_to_preload : function(config){
    return   this._cosmos_entities_to_preload(config).
      concat(this._manu_entities_to_preload(config));
  },

  _cosmos_entities_to_preload : function(config){
    var entities = [
      new Omega.SolarSystem(),
      new Omega.Galaxy(),
      new Omega.Star(),
      new Omega.JumpGate(),
    ];

    entities.concat(this._planets_to_preload(config));
    return entities;
  },

  _planets_to_preload : function(config){
    var planets   = [];
    var processed = [];
    for(var r in config.resources){
      if(r.substr(0,6) == 'planet'){
        var planet = new Omega.Planet({color: "00000" + r[6]});
        if(processed.indexOf(planet.colori()) == -1){
          planets.push(planet);
          processed.push(planet.colori());
        }
      }
    }

    return planets;
  },

  _manu_entities_to_preload : function(config){
    var entities = [];
    for(var s in config.resources.ships)
      entities.push(new Omega.Ship({type : s}));
    for(var s in config.resources.stations)
      entities.push(new Omega.Station({type : s}));
    return entities;
  },

  /// preload entity meshes and gfx to be cloned later
  preload_resources : function(config, event_cb){
    var entities = this._entities_to_preload(config);
    for(var e = 0; e < entities.length; e++)
      this.preload_entity_resources(entities[e], config, event_cb);
  },

  preload_entity_resources : function(entity, config, event_cb){
    if(entity.async_gfx) this.async_events += entity.async_gfx;
    entity.load_gfx(config, event_cb);
  },

  /// preload skybox backgrounds
  preload_skybox : function(config, event_cb){
    var skybox = new Omega.UI.CanvasSkybox();
    skybox.init_gfx();
    var num = Omega._num_backgrounds;
    this.async_events += num;
    for(var b = 1; b <= num; b++){
      skybox.set(b, config, event_cb);
    }
  },

  json : function(){
    if(!Omega.UI.Loader.json_loader)
      Omega.UI.Loader.json_loader = new THREE.JSONLoader();
    return Omega.UI.Loader.json_loader;
  },

  clear_universe : function(){
    var skeys = $.localStorage.keys();
    for(var k = 0; k < skeys.length; k++)
      if(skeys[k].substr(0, 13) == 'omega.cosmos.')
        $.localStorage.remove(skeys[k]);

    $.localStorage.remove('omega.universe_id');
  },

  _same_universe : function(retrieved){
    return $.localStorage.get('omega.universe_id') == retrieved;
  },

  _set_universe : function(val){
    $.localStorage.set('omega.universe_id', JSON.stringify(val));
  },

  /// Retrieve & store universe_id stat
  /// TODO url param that when detected will always force a cache invalidation
  load_universe : function(page, retrieval_cb){
    var _this = this;

    Omega.Stat.get('universe_id', null, page.node,
      function(stat_result){
        var id = stat_result.value;
        if(!_this._same_universe(id)) _this.clear_universe();
        _this._set_universe(id);
        if(retrieval_cb) retrieval_cb(id);
      });
  },

  _load_page_system : function(system_id, page, retrieval_cb){
    var system = page.entity(system_id);
    if(!system) return null;

    /// XXX for consistency would like to uncomment,
    /// but will result in infite recursive call w/
    /// how load_system is currently used, need to fix
    //if(retrieval_cb) retrieval_cb(system);
    return system;
  },

  _load_storage_system : function(system_id, page, retrieval_cb){
    var system = $.localStorage.get('omega.cosmos.' + system_id);
    if(!system || system == Omega.UI.Loader.placeholder) return null;

    system = RJR.JRMessage.convert_obj_from_jr_obj(system);
    system = new Omega.SolarSystem(system);
    page.entity(system_id, system);
    if(retrieval_cb) retrieval_cb(system);
    return system;
  },

  _loaded_remote_system : function(system, page, retrieval_cb){
    /// TODO make sure this is not overwriting components
    page.entity(system.id, system);
    var jr_system = RJR.JRMessage.convert_obj_to_jr_obj(system.toJSON());
    $.localStorage.set('omega.cosmos.' + system.id, jr_system);
    if(retrieval_cb) retrieval_cb(system);
  },

  _load_remote_system : function(system_id, page, retrieval_cb){
    var system = Omega.UI.Loader.placeholder;
    page.entity(system_id, system);

    var _this = this;
    Omega.SolarSystem.with_id(system_id, page.node,
      function(system){
        _this._loaded_remote_system(system, page, retrieval_cb);
      });

    return system;
  },

  load_system : function(system_id, page, retrieval_cb){
    /// first try to load from page cache
    var system = this._load_page_system(system_id, page, retrieval_cb);
    if(system) return system;

    /// then from browser storage
    system = this._load_storage_system(system_id, page, retrieval_cb);
    if(system) return system;

    /// then from server
    return this._load_remote_system(system_id, page, retrieval_cb);
  },

  _load_page_galaxy : function(galaxy_id, page, retrieval_cb){
    var galaxy = page.entity(galaxy_id);
    if(!galaxy) return null;

    /// same note about retrieval_cb as in load_system above
    return galaxy;
  },

  _load_storage_galaxy : function(galaxy_id, page, retrieval_cb){
    var galaxy = $.localStorage.get('omega.cosmos.' + galaxy_id);
    if(!galaxy || galaxy == Omega.UI.Loader.placeholder) return null;

    galaxy = RJR.JRMessage.convert_obj_from_jr_obj(galaxy);
    galaxy = new Omega.Galaxy(galaxy);
    page.entity(galaxy_id, galaxy);
    if(retrieval_cb) retrieval_cb(galaxy);
    return galaxy;
  },

  _loaded_remote_galaxy : function(galaxy, page, retrieval_cb){
    /// TODO make sure this is not overwriting components
    page.entity(galaxy.id, galaxy);
    var jr_galaxy = RJR.JRMessage.convert_obj_to_jr_obj(galaxy.toJSON());
    $.localStorage.set('omega.cosmos.' + galaxy.id, jr_galaxy);
    if(retrieval_cb) retrieval_cb(galaxy);
  },

  _load_remote_galaxy : function(galaxy_id, page, retrieval_cb){
    var _this  = this;
    var galaxy = Omega.UI.Loader.placeholder;
    page.entity(galaxy_id, galaxy);

    Omega.Galaxy.with_id(galaxy_id, page.node,
      function(galaxy){
        _this._loaded_remote_galaxy(galaxy, page, retrieval_cb);
      });

    return galaxy;
  },

  load_galaxy : function(galaxy_id, page, retrieval_cb){
    /// first try to load from page cache
    var galaxy = this._load_page_galaxy(galaxy_id, page, retrieval_cb);
    if(galaxy) return galaxy;

    /// then from browser storage
    galaxy = this._load_storage_galaxy(galaxy_id, page, retrieval_cb);
    if(galaxy) return galaxy;

    /// then from server
    return this._load_remote_galaxy(galaxy_id, page, retrieval_cb);
  },

  load_user_entities : function(user_id, node, cb){
    Omega.Ship.owned_by(user_id, node, cb);
    Omega.Station.owned_by(user_id, node, cb);
  },

  _loaded_default_systems : function(systems, page, cb){
    for(var s = 0; s < systems.length; s++){
      Omega.UI.Loader.load_system(systems[s], page, cb);
    }
  },

  /// XXX note callback will be invoked w/ each system individually
  load_default_systems : function(page, cb){
    // load systems w/ most ships/stations
    var _this = this;
    Omega.Stat.get('systems_with_most', ['entities', 5], page.node,
      function(stat_result){
        if(stat_result)
          _this._loaded_default_systems(stat_result.value, page, cb);
      });
  }
};
