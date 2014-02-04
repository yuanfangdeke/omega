## The Omega Simulation Framework

The Omega Project aims to develop a Universe Simulator accessible remotely
by registered users over the [JSON-RPC](http://en.wikipedia.org/wiki/JSON-RPC)
protocol.

This allows the most users and developers to access the universe and control
ships / stations / other entities in via many mechanisms.

You can see an instance running on the Omegaverse at
[omegaverse.info](http://omegaverse.info)

For a quick user tutorial see [this](http://github.com/movitto/omega/wiki/Tutorial).
To run your own node on the Omegaverse see the
[install](http://github.com/movitto/omega/wiki/Install) document.

## Overview

At the core of the simulation is
[omega-server](https://github.com/movitto/omega/blob/master/bin/omega-server),
the process that is responsible for registering the Omega subsystems and
listening for requests:

![overview.png](http://blog.omegaverse.info/images/overview.png)

Omega consists of several subsystems:

* **Motel** - Movable Objects Tracking Encompassing Locations - Tracks locations,
eg coordinates w/ an orientation and movement strategy, in 3d cartesian space.
The location's movement strategy periodically updates the location's properties.
(eg along linear, elliptical paths, following another location, etc)

* **Users** - User registrations, sessions, permissions, groups, etc

* **Cosmos** - Manages heirarchies of cosmos entities, galaxies, solar systems,
stars, planets, moons, asteroids, etc. Each cosmos entity is associated with
a location tracked by Motel.

* **Manufactured** - Manages player controlled and constructed entities,
ships, stations, etc. Similar to the cosmos subsystem, each manufactured entity
is associated with a location managed by Motel.

* **Missions** - Manages high level recurring events and goals. Privileged
users are permitted to create sequences of checks/operations which query/impact
other subsystems.

* **Stats** - Provides access to overall user and universe statistics. Other
subsystems may write to stats here and/or read stats to modify operations.

* **Omega** - Convenience utilities to bind the various server side subsystems
together, and provides simple mechanisms which to invoke functionality via a remote client.
This includes a simple dsl which can be used to setup a simulation as well as an
event based interface which to query/manipulate entities.


## Invoking

Entities may be controlled and subsystems may be queried via any programming
language and transport protocol. See the
[Clients](http://github.com/movitto/omega/wiki/Clients) page on the wiki for
more details.

The Omega Project also comes with an interactive web frontend based on
WebGL (via [three.js](http://threejs.org/)) and
[middleman](http://middlemanapp.com/). This is a completely optional component,
an Omegaverse node will run just fine w/out it, but if installed provides
a rich view to the node(s) which its configured for.

See the [Web UI](http://github.com/movitto/omega/wiki/Web UI) and
[Using the Web UI](http://github.com/movitto/omega/wiki/Using the Web UI)
wiki pages.

## Using

Generate documentation via

  rake yard

To run test suite:

  rake spec

## Legaleese

Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>

Omega is made available under version 3 of the
GNU AFFERO GENERAL PUBLIC LICENSE as published by the
Free Software Foundation

## Authors
* Mo Morsi <mo@morsi.org>
* Nicolas Satragno <nsatragno@gmail.com>
