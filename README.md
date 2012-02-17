Created 10 Feb 2012 -- Last change 14 Feb 2012  
By Victor Penso

Description
===========

_Collectd-Interface_ serves a web user-interface to data stored 
by [Collectd](http://collectd.org/). Furthermore it provides REST 
access to all data.

![Screenshot of User-Interface](https://github.com/vpenso/collectd-interface/raw/master/public/readme/user-interface.png  "Screenshot of the User-Interface")

Installation
============

Download and install Collectd following the instructions 
from the developers. 

On Debian flavored Linux use:

    apt-get install collectd rrdtool

You will need the [RRDtool](http://oss.oetiker.ch/rrdtool/) too.

Install the Collectd-Interface Gem:

    gem install collectd-interface

Usage
=====

Get help:

    collectd-interface-daemon --help

Start the Collectd Interface in fore-ground:

    collectd-interface-daemon

Open the web-interface <a href='localhost:4567'>localhost:4567</a>.

Start the Collectd Interface as daemon:

    collectd-interface-daemon -p 5000 -l /var/log/ -P /var/run/ &


Interfaces
==========

Collectd-Interface servers three different kinds of output:

1. `/graph` is the user-interface showing line charts of many
   of the data accumulated by Collectd.
2. `/report` presents tables of system specific information
   like disk capacity of a list of network sockets.
3. `/data` servers an REST API to all data available from 
   Collectd.

All content from `/graph`, `/report` and `/data` is accessible 
by a REST interface, to allow embedding this content into other
applications.

Graph
-----

You can select individual graphs using the drop-down menu followed by 
clicking the "Show" button. In case you just want to have the image, to
embed it into another web-page, use the links beneath the graph.

Once the graph is generated the caller will be redirected to `/image/`.

**Parameters**

It is possible to limit the time-frame of the graph using the option
`last=10h`(us (m)inutes,(d)ays or (w)eeks). 

This simple example:

    http://.../memory?last=1w&image=svg

Requests an SVG image with the memory graph for the last week.

**Plugin**

You can create add a custom graph rendering data from Collectd
by creating a template which is used to generate the <tt>rrdtool graph</tt>.
Take a look to the <tt>graphs/</tt> and <tt>disabled/graphs/</tt> directories 
for examples. I recommend you the start the Collectd-Interface in
debug mode (option <tt>-d</tt>) while you develop new graph templates.

In case you want to enable graphs from <tt>disabled/graphs/</tt> create 
a soft link from <tt>graphs/</tt>. The <tt>collectd-interface</tt> daemon will 
automatically recognize new templates within <tt>graphs</tt> on start.

Report
------

Reports a basically wrappers around commands like <tt>df -l</tt> or
<tt>ss -ar</tt>. The output is available as HTML in the "Report" section
of the user-interface. 

TODO

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

Copyright 2011 Victor Penso  
License [GPLv3](http://www.gnu.org/licenses/gpl-3.0.html) (see LICENSE file)
