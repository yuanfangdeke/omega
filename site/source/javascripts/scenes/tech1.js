/* Omega Tech Demo 1 Scene
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "scenes/common"
//= require "scenes/tech1/audio"
//= require "scenes/tech1/setting"

Omega.Scenes.Tech1 = function(){
  this.audio   = new Omega.Scenes.Tech1Audio();
  this.setting = new Omega.Scenes.Tech1Setting();
};

Omega.Scenes.Tech1.prototype = {
  id : 'tech1',

  /// load scene components
  _load_scene : function(page, cb){
    this.setting.load(cb);
  },

  /// setup scene components
  _setup_scene : function(page){
    page.canvas.set_scene_root(this.setting.system);
    var scene_components = this.setting.scene_components();
    for(var s = 0; s < scene_components.length; s++){
      page.canvas.add(scene_components[s]);
    }

    page.canvas.add(this.setting.skybox, page.canvas.skyScene);
    this.setting.skybox.set(2, Omega.UI.Canvas.trigger_animation(page.canvas));
  },

  /// initialize scene camera
  _init_cam : function(page){
    page.canvas.cam.position.set(2500, 2500, -2500);
    page.canvas.follow(this.setting.ships[3].position_tracker());
    page.canvas.cam_controls.update();

    this.transition = new THREE.Vector3(10, 10, -10);
    this.orbit_started = false;
  },

  /// camera zoom timer callback
  _cam_effects : function(page){
    if(page.canvas.cam.position.length() > 500){
      page.canvas.cam.position.sub(this.transition);

    }else if(!this.orbit_started){
      this.start_orbit(page);
    }

    page.canvas.cam_controls.update();
  },

  start_orbit : function(page){
    this.orbit_started = true;
    page.canvas.cam_controls.autoRotate = true;
    page.canvas.cam_controls.autoRotateSpeed = -3.0;
  },

  /// create effect timers
  _create_timers : function(page){
    var _this = this;

    this.effects_timer = $.timer(function(){
      _this._cam_effects(page);
    }, Omega.UI.EffectsPlayer.prototype.interval, false);
  },

  /// run scene
  run : function(page){
    var _this = this;
    this._load_scene(page, function(){
      _this._setup_scene(page);
      _this._init_cam(page);
      _this._create_timers(page);

      page.audio_controls.play(_this.audio);
      _this.effects_timer.play();
    });
  },

  /// stop scene
  stop : function(page){
    if(this.effects_timer) this.effects_timer.stop();
    page.audio_controls.stop();
    page.canvas.clear();
  }
};
