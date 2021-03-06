/* Omega Jump Gate Trigger Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.JumpGateTriggerAudioEffect = function(args){
  if(!args) args = {};
  this.audio = Omega.Config.audio['trigger'];
};

$.extend(Omega.JumpGateTriggerAudioEffect.prototype, Omega.BaseAudioEffect);
