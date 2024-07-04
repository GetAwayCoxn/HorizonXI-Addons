# Updated to Ashita v4 by Zal Das and GetAwayCoxn

This is a simple counter addon.  When you begin to /heal, it counts down from 20 to 0, and when a healing tick is detected, it resets to 10 and starts counting down to 0 again. The healing tick may occur 1-2 seconds before or after the counter hits 0 as server flush and packet travel time can't be known with 100% precision client-side, so this should be treated as an approximation counter and not an absolute source of truth.

#### Note by GetAwayCoxn
I tried to get this PR'd into Hugin's (Horizon XI staff member) repo since they decided to host this addon because it was only floating around on Ashita's discord server threads and that way they could link it from Horizon's approved addon list and have it be more easily found I assume. However the PR sat untouched for a couple months so I just closed it out and am going to host it on this repo in case anyone finds the settings fix useful.

Link to Hugin's repo: https://github.com/clanofartisans/ticker

## Version 1.1
- Added missing settings_update hook to fix settings not being handled correctly on login/logout/update
- Added some basic logic to try and improve the overall accuracy of the timer, however due to the mentions above it still is not 100% accurate but is close enough