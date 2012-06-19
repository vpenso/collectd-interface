Created 10 Feb 2012 -- Last change 14 Feb 2012  
By Victor Penso

Description
===========

_Collectd-Interface_ provides a web user-interface to data stored 
by Collectd. Furthermore it serves a REST 
interface to all RRD files of Collectd.

![Screenshot of User-Interface](https://github.com/vpenso/collectd-interface/raw/master/public/readme/user-interface.png  "Screenshot of the User-Interface")

Installation
============

Download and install [Collectd](http://collectd.org/) following the instructions 
from the developers. 

On Debian flavored Linux use:

    apt-get install collectd rrdtool

You will need [RRDtool](http://oss.oetiker.ch/rrdtool/) too.

Install the Collectd-Interface RubyGem:

    gem install collectd-interface

Usage
=====

Get help:

    collectd-interface-daemon --help

Start the Collectd-Interface in fore-ground:

    collectd-interface-daemon

Open the web-interface at <a href='localhost:4567'>localhost:4567</a>.
Collectd-Interface expects the RRD file in `/var/lib/collectd/rrd/`
by default. Overwrite it with the option `-f PATH`.

Start the Collectd-Interface as daemon:

    collectd-interface-daemon -p 5000 -l /var/log/ -P /var/run/ &

Collectd-Interface supports plugins for graphs and reports:

    collectd-interface-daemon --port 5000 --plugin-path /var/collectd/plugins

Find a collection of plugins in the [collectd-interface-plugins][plug] repository.

[plug]: https://github.com/vpenso/collectd-interface-plugins


Interfaces
==========

Collectd-Interface servers three different interfaces:

1. `/graph` is the user-interface showing line charts of many
   of the data accumulated by Collectd.
2. `/report` presents tables of system specific information
   like disk capacity or a list of network sockets.
3. `/data` servers an REST API to all data available from 
   Collectd RRD files.

All content from `/graph`, `/report` and `/data` is accessible 
by a REST interface, to allow embedding this content into other
applications.

Graph
-----

You can select individual graphs using the drop-down menu followed by 
clicking the "Show" button. In case you just want to have the image, to
embed it into another web-page, use the links beneath the graph. Once 
the graph is generated the caller will be redirected to `/image/`.

**Parameters**

It is possible to limit the time-frame of the graph using the option
_start_ and _end_. They are available in the drop-down menu, and can
be defined using the input fields or by appending them as URL 
parameters.

Following URLs demonstrate the selection of a specific graph with 
parameters to define a time-frame:

    http://.../load?start=end-1d&end=now-2h
    http://.../cpus?start=20120217&end=20120220
    http://.../memory?start=end-48h&end=20120218
    http://.../network-eth0?start=20120217&end=now&image=svg

**Plugins**

Each graph is generated from a plugin in `views/graphs/`. This 
directory is scanned when the Collectd-Interface daemon is started, 
and each ERB-template (`*.erb`) is registered. Enable/disable 
certain plugins using the command `collectd-interface-plugins`. 

Data
----

List all available values <a href="/data/">/data/</a> from 
Collectd. Get the time-series of a specific value.

    http://.../data/interface/if_packets-eth0/rx

By default the severs will answer with averages 
of all data-points and an HTML document.

**Parameters**

    http://.../value?last=36h&resolution=3600

Request only values from the last 36 hours, with a
data point resolution of 1 hour (3600 seconds).
Default resolution is the highest possible and you
will get by default values of the last 24 hours.
In the time specification you can also use (w)eeks,
(d)ays and (m)inutes.

    http://.../rx?function=max&format=json

Request the maximum of all data points for the past
in the JSON format. Other consolidation functions
are average (default) and min, for the smallest value
in a time-frame.

Copying
=======

Copyright 2012 Victor Penso

This is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public
License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public
License along with this program. If not, see 
<http://www.gnu.org/licenses/>.
