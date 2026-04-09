A fully-featured, performance-optimised player-owned business system for FiveM ESX servers.

**Resource Monitor:** `0.00 – 0.01 ms` | **Framework:** ESX | 

**Features**

**Business Ownership**
- Purchase unowned businesses directly in-world via NPC interaction
- List your business **for sale** at a custom price or sell back to the server
- Multiple business types: **YouTool**, **Food Shop**, **Drink Shop**, **Weapon Shop**

**Shop & Wholesale**
- Each business has its own **stock inventory** with configurable max limits
- Owners set their own **item prices** to control profit margins
- Dedicated **wholesale supplier NPC** for bulk restocking
- Cash or bank payment supported everywhere

**Employees & Wages**
- Hire/fire employees by player ID, assign roles and custom wages
- Automated **wage payouts** on a configurable per-business interval
- Wages are deducted from the business's earnings pool — no money spawned

**Earnings**
- Every sale adds to the business's **earnings pool**
- Owners withdraw earnings to their bank at any time
- Full sales history logged to the database

**World & Admin**
- NPCs **stream in/out dynamically** based on player proximity
- **ox_target** zones on shop counters and management NPCs
- Configurable **map blips** per business type
- `/managebusiness` admin panel with an in-game **coordinate picker** to place NPCs anywhere

**Commands**

| `/managebusiness` | Admin | Open the admin panel to create, place, and delete businesses |

**Dependencies**

[es_extended](https://github.com/esx-framework/esx_core) | Core framework |
[ox_lib](https://github.com/overextended/ox_lib) | UI, callbacks, notifications |
[ox_target](https://github.com/overextended/ox_target) | In-world interaction zones |
[ox_inventory](https://github.com/overextended/ox_inventory) | Item & inventory management |
[oxmysql](https://github.com/overextended/oxmysql) | Database |
