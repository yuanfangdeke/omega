/* Omega Ship Mining Vector Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/particles"

Omega.ShipMiningVector = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  this.init_gfx(event_cb);
  this._update_velocity = this._no_velocity_update;
};

Omega.ShipMiningVector.prototype = {
  num_emitters         :   4,
  particle_age         :   2,
  particle_count       :   2,
  particle_size        :  50,

  _particle_group : function(event_cb){
    /// TODO mining-specific particle
    return new SPE.Group({
      texture:    Omega.UI.Particles.load('ship', event_cb),
      maxAge:     this.particle_age,
      blending:   THREE.AdditiveBlending
    });
  },

  _particle_emitter : function(){
    return new SPE.Emitter({
      colorStart    : new THREE.Color(0x5a555a),
      colorEnd      : new THREE.Color(0x5a555a),
      sizeStart     : this.particle_size,
      sizeEnd       : this.particle_size,
      opacityStart  : 1,
      opacityEnd    : 1,
      velocity      : new THREE.Vector3(0, 0, 1),
      particleCount : this.particle_count,
      alive         : 0
    });
  },

  init_gfx : function(event_cb){
    var group    = this._particle_group(event_cb);
    var emitters = [];
    for(var e = 0; e < this.num_emitters; e++)
      group.addEmitter(this._particle_emitter());
    this.particles = group;
    this.clock = new THREE.Clock();
  },

  clone : function(){
    return new Omega.ShipMiningVector();
  },

  update : function(){
    this._update_velocity();
  },

  update_state : function(){
    if(this.has_target()){
      if(!this.alive()) this.enable();
      this._update_velocity = this._update_emitter_velocity;

    }else if(this.alive()){
      this.disable();
      this._update_velocity = this._no_velocity_update;
    }
  },

  /// intentionally blank, see above
  _no_velocity_update : function(){},

  _update_emitter_velocity : function(){
    var loc = this.omega_entity.scene_location();

    for(var e = 0; e < this.num_emitters; e++){
      var emitter = this.particles.emitters[e];
      var epos    = emitter.position;
      var edist   = loc.distance_from(epos.x, epos.y, epos.z);

      var rand    = Math.random() * 10;
      var vel     = edist / this.particle_age + rand;
      var dx      = (loc.x - epos.x) / edist * vel;
      var dy      = (loc.y - epos.y) / edist * vel;
      var dz      = (loc.z - epos.z) / edist * vel;

      emitter.velocity.set(dx, dy, dz);
    }
  },

  target : function(){
    return this.omega_entity.mining_asteroid;
  },

  target_mesh : function(){
    return this.target().mesh.tmesh;
  },

  has_target : function(){
    return !!(this.target()) && !!(this.target().mesh);
  },

  random_target_vertex : function(){
    var vertices = this.target_mesh().geometry.vertices;
    var index = Math.floor(Math.random()*vertices.length);
    return vertices[index];
  },

  alive : function(){
    return !!(this.particles.emitters[0].alive);
  },

  enable : function(){
    for(var e = 0; e < this.num_emitters; e++){
      var emitter = this.particles.emitters[e];
      emitter.alive = true;

      var vertex = this.random_target_vertex().clone();
      vertex.applyMatrix4(this.target_mesh().matrixWorld);
      emitter.position.set(vertex.x, vertex.y, vertex.z);
    }
  },

  disable : function(){
    for(var e = 0; e < this.num_emitters; e++){
      this.particles.emitters[e].alive = false;
      this.particles.emitters[e].reset();
    }
  },

  run_effects : function(){
    this.particles.tick(this.clock.getDelta());
  }
};
