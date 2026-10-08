# Google Play IAP — SubTrack

Package: `com.SubTrackMNG.SubTrack`

Remote config: `https://api2.blwsmartware.net/N311.json`  
If JSON field `disable` is `1`, hide Google Play purchase popups. Shop stays open for coin unlocks.

## Consumable coin packs (buy many times)

| Product ID | Coins |
| --- | --- |
| `st_pack_1` | 50 |
| `st_pack_2` | 100 |
| `st_pack_3` | 200 |
| `st_pack_4` | 350 |
| `st_pack_5` | 500 |
| `st_pack_6` | 750 |
| `st_pack_7` | 1000 |
| `st_pack_8` | 1500 |
| `st_pack_9` | 2200 |
| `st_pack_10` | 3000 |

## One-time

| Product ID | Unlock |
| --- | --- |
| `st_remove_ads` | Hide the banner |
| `st_pro` | More than 8 plans |

Create these IDs in Play Console → Monetize → In-app products. Coin packs must be **consumable**. Remove ads and Pro must be **non-consumable**.
