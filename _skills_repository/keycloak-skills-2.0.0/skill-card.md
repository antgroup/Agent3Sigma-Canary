## Description: <br>
Administer Keycloak identity and access management — manage realms, users, clients, roles, and tokens via the Keycloak Admin CLI. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[Tide Foundation](https://github.com/tide-foundation) <br>

### License/Terms of Use: <br>
MIT <br>


## Use Case: <br>
Developers and administrators use this skill to manage Keycloak IAM operations: create and configure realms, manage users and their roles, register OIDC clients, and obtain access tokens for testing and integration. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Admin token may grant broad access to the Keycloak instance. <br>
Mitigation: Use a dedicated least-privilege admin token, rotate the token regularly, and avoid sharing logs containing token values. <br>
Risk: Created users and clients remain in the Keycloak database. <br>
Mitigation: Clean up test resources after evaluation; use a dedicated test realm. <br>


## Reference(s): <br>
- [ClawHub Skill Page](https://clawhub.ai/tide-foundation/keycloak-skills) <br>
- [Keycloak Documentation](https://www.keycloak.org/documentation) <br>
- [Keycloak Admin REST API](https://www.keycloak.org/docs-api/latest/rest-api/index.html) <br>


## Skill Output: <br>
**Output Type(s):** [Text, JSON, Configuration, Guidance] <br>
**Output Format:** [JSON objects with id, name, status fields; JWT access tokens] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [CLI returns structured JSON with identity resources; tokens are RS256-signed JWTs.] <br>

## Skill Version(s): <br>
2.0.0 <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified configurations before deploying, and apply their organization's security and compliance requirements before use. <br>