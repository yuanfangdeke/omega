/* Omega Intro Scene
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "scenes/intro/audio"
//= require "scenes/intro/title"

Omega.Scenes.Intro = function(){
  this.audio = new Omega.Scenes.IntroAudio();
  this.title = new Omega.Scenes.IntroTitle("THE OMEGAVERSE");
};

Omega.Scenes.Intro.prototype = {
  id : 'intro',

  run : function(page){
    var _this = this;

    page.canvas.cam.position.set(0, 0, 1500);
    page.canvas.focus_on({x:0,y:0,z:0});
    page.canvas.scene.add(new THREE.DirectionalLight(0xFFFFFF, 1.0));

    page.audio_controls.play(this.audio);

    /// timer to zoom camera into origin
    this.cam_timer = $.timer(function(){
      page.canvas.cam.position.z -= 1;
    }, 50, true);

    /// timer to show title
    this.show_title = $.timer(function(){
      page.audio_controls.play(_this.audio);
      page.canvas.add(_this.title);
      this.stop();
    }, 3000, true);

    /// timer to remove title near end
    this.hide_title = $.timer(function(){
      page.canvas.remove(_this.title);
      this.stop();
    }, 13000, true);
  },

  stop : function(page){
    if(this.cam_timer)  this.cam_timer.stop();
    if(this.show_title) this.show_title.stop();
    if(this.hide_title) this.hide_title.stop();
    this.audio.reset();
    page.canvas.remove(this.title);
    page.audio_controls.stop();
  }
};
