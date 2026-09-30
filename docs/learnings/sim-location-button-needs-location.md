---
name: sim-location-button-needs-location
description: MapUserLocationButton on the map tab does nothing on the simulator until a location is simulated and permission granted
type: gotcha
area: Views/Map
---

The top-right arrow on `NEIMapView` is MapKit's `MapUserLocationButton`. On the
simulator it is a silent no-op until two things are true: the simulator has a
location set, and the app has location permission. No blue dot on the map means
no location, and no location means the button has nothing to centre on.

**Why:** A fresh or erased simulator has no location, so the button looks broken
and gets reported as a bug. Setting a location can also bring up the permission
prompt the app requested earlier.
**How to apply:** Before touching the code, run
`DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun simctl location booted set 52.2320,21.0067`
(central Warsaw) or use Features → Location in Simulator, then tap "Allow While Using App".
Plain `xcrun simctl` fails here without `DEVELOPER_DIR` because the only Xcode
installed is Xcode-beta.
