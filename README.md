# Vault Presentation

[Slides](http://imgur.com/a/oaG1F)

## Hello, World

```bash
$ make build
$ export VAULT_ADDR='http://127.0.0.1:8200'
$ ROOT_TOKEN=$(docker logs vault-server 2>&1 | grep "Root Token" | awk '{print $3}')
$ vault login ${ROOT_TOKEN?}
$ vault status
```

```bash
$ vault kv put  secret/hello value=world
$ echo -n "brewcore" | vault kv put secret/password value=-
$ cat data.json
$ vault kv put secret/password @data.json
$ vault kv get -field=value secret/password
$ cat data.txt
$ vault kv put secret/password value=@data.txt
$ vault kv get -field=value secret/password
$ vault kv get -format=json secret/password
$ vault kv delete secret/password
```

## Dynamic Secrets

### Setup Server

```bash
$ make build
$ export VAULT_ADDR='http://127.0.0.1:8200'
$ ROOT_TOKEN=$(docker logs vault-server 2>&1 | grep "Root Token" | awk '{print $3}')
$ vault auth ${ROOT_TOKEN?}
```

#### Output

```bash
[~/Git/Vault-Presentation] export VAULT_ADDR='http://127.0.0.1:8200'
[~/Git/Vault-Presentation] ROOT_TOKEN=$(docker logs vault-server 2>&1 | grep "Root Token" | awk '{print $3}')
[~/Git/Vault-Presentation] vault auth ${ROOT_TOKEN?}
Successfully authenticated! You are now logged in.
token: 85edb328-ca3d-8e0e-47ac-0f790a802bad
token_duration: 0
token_policies: [root]
```

### Mount Database

```bash
$ vault secrets enable databasee

$ vault kv put database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="db-readonly, db-readwrite, db-dba" \
    connection_url="postgresql://vault:vault@172.17.0.2:5432/postgres?sslmode=disable"

$ vault kv put database/roles/db-readonly \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
    renew_statements="ALTER ROLE \"{{name}}\" PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
    default_ttl="1h" \
    max_ttl="24h"

$ vault kv put  database/roles/db-readwrite \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
    renew_statements="ALTER ROLE \"{{name}}\" PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
    default_ttl="1h" \
    max_ttl="24h"

 $ vault kv put database/roles/db-dba \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH SUPERUSER LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
    revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
    renew_statements="ALTER ROLE \"{{name}}\" PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
    default_ttl="1h" \
    max_ttl="24h"
```

#### Output

```bash
[~/Git/Vault-Presentation] vault secrets enable database 
Success! Enabled the database secrets engine at: database/

[~/Git/Vault-Presentation] vault kv put database/config/postgresql \
>     plugin_name=postgresql-database-plugin \
>     allowed_roles="db-readonly, db-readwrite, db-dba" \
>     connection_url="postgresql://vault:vault@172.17.0.2:5432/postgres?sslmode=disable"
WARNING! The following warnings were returned from Vault:

  * Password found in connection_url, use a templated url to enable root
  rotation and prevent read access to password information.


[~/Git/Vault-Presentation] vault kv put database/roles/db-readonly \
>     db_name=postgresql \
>     creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
>         GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
>     revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
>     renew_statements="ALTER ROLE \"{{name}}\" PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
>     default_ttl="1h" \
>     max_ttl="24h"
Success! Data written to: database/roles/db-readonly

[~/Git/Vault-Presentation] vault kv put database/roles/db-readwrite \
>     db_name=postgresql \
>     creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
>         GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
>     revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
>     renew_statements="ALTER ROLE \"{{name}}\" PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
>     default_ttl="1h" \
>     max_ttl="24h"
Success! Data written to: database/roles/db-readwrite

[~/Git/Vault-Presentation] vault kv put database/roles/db-dba \
>     db_name=postgresql \
>     creation_statements="CREATE ROLE \"{{name}}\" WITH SUPERUSER LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
>     revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
>     renew_statements="ALTER ROLE \"{{name}}\" PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
>     default_ttl="1h" \
>     max_ttl="24h"
Success! Data written to: database/roles/db-dba
```

### Create Policy

```bash
$ vault kv put sys/policy/db-readonly policy=@./policy/db-readonly.hcl
$ vault kv put sys/policy/db-readwrite policy=@./policy/db-readwrite.hcl
$ vault kv put sys/policy/db-dba policy=@./policy/db-dba.hcl
```

#### Output

```bash
[~/Git/Vault-Presentation/policy] vault kv put sys/policy/db-readonly rules=@./policy/db-readonly.hcl
Success! Data written to: sys/policy/db-readonly

[~/Git/Vault-Presentation/policy] vault kv put sys/policy/db-readwrite rules=@./policy/db-readwrite.hcl
Success! Data written to: sys/policy/db-readwrite

[~/Git/Vault-Presentation/policy] vault kv put sys/policy/db-dba rules=@./policy/db-dba.hcl
Success! Data written to: sys/policy/db-dba
```

### Create Token

```bash
$ vault token create -policy=db-readonly -period=1h
$ vault token create -policy=db-readwrite -period=1h
$ vault token create -policy=db-dba -period=1h
```

#### Output

```bash
[~/Git/Vault-Presentation/policy] vault token create -policy=db-readonly -period=5m
Key             Value
---             -----
token           200b2645-486c-e07b-3c10-f06e1e51174a
token_accessor  8694ec93-9cec-98a0-87d8-c3310cd6c2dd
token_duration  1h0m0s
token_renewable true
token_policies  [db-readonly default]

[~/Git/Vault-Presentation/policy] vault token create -policy=db-readwrite -period=5m
Key             Value
---             -----
token           14ef5dbd-79a3-6634-4fe4-90395132c0d3
token_accessor  9b1f4397-fcb9-a3fd-46f2-2e8a750dcd3e
token_duration  1h0m0s
token_renewable true
token_policies  [db-readwrite default]

[~/Git/Vault-Presentation/policy] vault token create -policy=db-dba -period=5m
Key             Value
---             -----
token           ba04bc5e-baf4-c54e-61fc-41926bf678a1
token_accessor  71f51e9c-42a7-454d-28be-4c64182d66d9
token_duration  1h0m0s
token_renewable true
token_policies  [db-dba default]
```

### Use Token

```bash
$ vault login
$ vault kv get database/creds/db-readonly
```

#### Output

```bash
[~/Git/Vault-Presentation] vault login
Token (will be hidden): 
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                Value
---                -----
token              247e794b-69bc-63a3-de4c-deeacfc47e3c
token_accessor     c597fca1-4d01-6de9-d1a6-68a24de34293
token_duration     ∞
token_renewable    false
token_policies     [root]

[~/Git/Vault-Presentation] vault kv get database/creds/db-readonly
====== Data ======
Key         Value
---         -----
password    A1a-4zs7w06tz79r2r8r
username    v-token-db-reado-v7s5471r2vxu6465stt9-1527075695
```

### PostgreSQL Roles

```bash
postgres=# \du
                                                       List of roles
                    Role name                     |                         Attributes                         | Member of 
--------------------------------------------------+------------------------------------------------------------+-----------
 postgres                                         | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 v-root-db-reado-9q5qzr86z9wutr7w3ppp-1527075188  | Password valid until 2018-06-24 07:33:13-04                | {}
 v-root-db-reado-w100w44w8xq3p02rz85s-1527075118  | Password valid until 2018-06-24 07:32:03-04                | {}
 v-root-db-reado-x64tpwzxr1qs48z13964-1527074949  | Password valid until 2018-06-24 07:29:14-04                | {}
 v-token-db-reado-v7s5471r2vxu6465stt9-1527075695 | Password valid until 2018-06-24 07:41:40-04                | {}
 vault                                            | Superuser                                                  | {}
```
