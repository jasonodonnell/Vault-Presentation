```bash
make build
export VAULT_ADDR='http://127.0.0.1:8200'
ROOT_TOKEN=$(docker logs vault-server 2>&1 | grep "Root Token" | awk '{print $3}')
vault auth ${ROOT_TOKEN?}

vault mount database

vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="db-readonly, db-readwrite, db-dba" \
    connection_url="postgresql://vault:vault@172.17.0.2:5432/postgres?sslmode=disable"

vault write database/roles/db-readonly \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
    default_ttl="1h" \
    max_ttl="24h"

vault write database/roles/db-readwrite \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
    default_ttl="1h" \
    max_ttl="24h"

vault write database/roles/db-dba \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH SUPERUSER LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
    revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
    default_ttl="1h" \
    max_ttl="24h"

vault write sys/policy/db-readonly rules=@./policy/db-readonly.hcl
vault write sys/policy/db-readwrite rules=@./policy/db-readwrite.hcl
vault write sys/policy/db-dba rules=@./policy/db-dba.hcl

vault token-create -policy=db-readonly -period=1h
vault token-create -policy=db-readwrite -period=1h
vault token-create -policy=db-dba -period=1h


curl -Ssl \
    -H "X-Vault-Token: " \
    -X GET \
    http://127.0.0.1:8200/v1/database/creds/db-readonly

curl -Ssl \
    -H "X-Vault-Token: " \
    -X GET \
    http://127.0.0.1:8200/v1/database/creds/db-readwrite

curl -Ssl \
    -H "X-Vault-Token: " \
    -X GET \
    http://127.0.0.1:8200/v1/database/creds/db-dba

vault auth
vault read database/creds/db-readonly
vault read database/creds/db-readwrite
vault read database/creds/db-dba

vault token-revoke <TOKEN>
```
