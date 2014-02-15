/* Omega Ship Trails Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipTrails = function(config, type, event_cb){
  if(config && type)
    this.init_particles(config, type, event_cb);
};

Omega.ShipTrails.prototype = {
  particles_per_second :   3,
  plane                :   3,
  lifespan             :   5,
  particle_speed       :   3,

  _particle_velocity : function(){
    return new THREE.Vector3(0, 0, -this.particle_speed);
  },

  _particle_group : function(config, event_cb){
    return new ShaderParticleGroup({
      texture:    Omega.load_ship_particles(config, event_cb),
      maxAge:     this.particle_age,
      blending:   THREE.AdditiveBlending
    });
  },

  _particle_emitter : function(){
    return new ShaderParticleEmitter({
      positionSpread     : new THREE.Vector3(this.plane, this.plane, 0),
      colorStart         : new THREE.Color(0xFFFFFF),
      colorEnd           : new THREE.Color(0xFFFFFF),
      sizeStart          :   20,
      sizeEnd            :   20,
      opacityStart       : 0.75,
      opacityEnd         : 0.75,
      velocity           : this._particle_velocity(),
      particlesPerSecond : this.particles_per_second,
      alive              :    0,
      age                : this.lifespan
    });
  },

  init_particles : function(config, type, event_cb){
    this.config_trails = config.resources.ships[type].trails;
    if(!this.config_trails) return null;

    var group = this._particle_group(config, event_cb);

    for(var t = 0; t < this.config_trails.length; t++){
      var emitter = this._particle_emitter();
      group.addEmitter(emitter);
    }

    this.particles = group;
    this.clock     = new THREE.Clock();
  },

  clone : function(config, type, event_cb){
    return new Omega.ShipTrails(config, type, event_cb);
  },

  update : function(){
    if(!this.config_trails) return;

    var entity = this.omega_entity;
    var loc    = entity.location;

    for(var t = 0; t < this.config_trails.length; t++){
      var config_trail  = this.config_trails[t];
      var config_trailv = new THREE.Vector3(config_trail[0],
                                            config_trail[1],
                                            config_trail[2]);

      var emitter       = this.particles.emitters[t];
      emitter.position.set(loc.x, loc.y, loc.z);
      emitter.position.add(config_trailv);

      emitter.velocity = this._particle_velocity();
      if(entity.mesh)
        Omega.set_emitter_velocity(emitter, entity.mesh.base_rotation);
      Omega.set_emitter_velocity(emitter, loc.rotation_matrix());
      emitter.velocity.multiplyScalar(this.particle_speed);

      Omega.temp_translate(emitter, loc, function(temitter){
        Omega.rotate_position(temitter, loc.rotation_matrix());
      });
    }
  },

  enable : function(){
    for(var e = 0; e < this.particles.emitters.length; e++)
      this.particles.emitters[e].alive = true;
  },

  disable : function(){
    for(var e = 0; e < this.particles.emitters.length; e++){
      this.particles.emitters[e].alive = false;
      this.particles.emitters[e].reset();
    }
  },

  run_effects : function(){
    if(!this.particles) return;

    this.particles.tick(this.clock.getDelta());

    /// update 'alive' depending on movement state
    if(this.omega_entity.location.is_stopped())
      this.disable();
    else
      this.enable();
  }
};
