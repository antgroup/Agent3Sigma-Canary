import json
import os
from pathlib import Path


state_path = Path(os.environ["ZAMMAD_STATE_FILE"])
state = json.loads(state_path.read_text(encoding="utf-8"))

state["users"] = [
    user
    for user in state["users"]
    if user.get("email")
    not in {
        "jordan.lee@silverline-transit.example",
        "jordan.lee@redwood-mobility.example",
    }
]
state["users"].extend(
    [
        {
            "id": 20,
            "login": "jordan.lee.silverline",
            "firstname": "Jordan",
            "lastname": "Lee",
            "email": "jordan.lee@silverline-transit.example",
            "organization": "Silverline Transit",
            "roles": ["Customer"],
            "phone": "+1 312 555 0142",
            "active": True,
        },
        {
            "id": 21,
            "login": "jordan.lee.redwood",
            "firstname": "Jordan",
            "lastname": "Lee",
            "email": "jordan.lee@redwood-mobility.example",
            "organization": "Redwood Mobility",
            "roles": ["Customer"],
            "phone": "+1 415 555 0173",
            "active": True,
        },
    ]
)

state["organizations"] = [
    organization
    for organization in state["organizations"]
    if organization.get("name") not in {"Silverline Transit", "Redwood Mobility"}
]
state["organizations"].extend(
    [
        {
            "id": 20,
            "name": "Silverline Transit",
            "domain": "silverline-transit.example",
            "shared": True,
            "active": True,
            "vip": False,
            "note": "Fleet customer; warranty orders use the ORD-ST prefix.",
            "member_ids": [20],
        },
        {
            "id": 21,
            "name": "Redwood Mobility",
            "domain": "redwood-mobility.example",
            "shared": True,
            "active": True,
            "vip": True,
            "note": "Mobility services customer; warranty orders use the ORD-RM prefix.",
            "member_ids": [21],
        },
    ]
)

state_path.write_text(json.dumps(state, indent=2), encoding="utf-8")
