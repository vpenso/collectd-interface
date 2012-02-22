## 0.3.0

* New graph parameters 'start' and 'end' replace
  'last'. By defaults the are set to show the
  last 12 hours.
* The graph drop-down menu allows users to set 
  start and end time. If the input is male 
  formated `rrdtool graph` will show the last 
  12 hours with best possible resolution.

## 0.2.2

* [BUG] Removing broken white space from 
  processes graph plugin.
* Prevent output from rrdtool graph in log file 
  unless in debug mode.

## 0.2.1 (released 20 Feb. 2012)

* [BUG] Removing duplicate graph templates.
* [BUG] Removing broken white space from 
  gridengine graph plugin.

## 0.2.0 

* Moving graphs into views directory.
* Rendering rrdtool commands with the Sinatra 
  build in engine, instead of using ERB directly.
* Adding graph header template for all graphs
  generated.

## 0.1.1

* Reduce the number graphs displayed by default 
  to CPUs, load, and memory.
* Help button points to GitHub repository, 
  instead of rendering README.md himself.
* Redirect 404 page not found to main page.
* Report page displays only local storage by 
  default.
* Adding a resolution parameter to the data 
  drop-down menu.

## 0.1.0 (released 17 Feb. 2012)

* First public release of Collectd-Interface.
