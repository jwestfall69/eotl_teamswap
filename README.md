# eotl_teamswap

This is a TF2 sourcemod plugin I wrote for the [EOTL](https://www.endofthelinegaming.com/) community.

This plugin provides a !teamswap command that allows a player force swap to the other team.


### Dependencies
<hr>

This plugin depends on eotl_vip_core plugin.


### Say Commands
<hr>

**!teamswap**

Makes the player swap to the other team

### ConVars
<hr>

**eotl_teamswap_viponly [0/1]**<br>

Restrict !teamswap command to vips only (1) or anyone (0)

Default: 1 (vip only)

**eotl_teamswap_mintime [seconds]**<br>

Only allow the player to swap teams every [seconds] seconds

Default: 120

**eotl_teamswap_deny_full [0/1]**<br>

Deny a teamswap if the target team is full (maxplayers / 2)

Default: 1 (deny)

