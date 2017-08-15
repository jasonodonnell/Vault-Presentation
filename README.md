# Vault Presentation

* Secure Secret Storage
  * KV Secrets
  * Disk, Consul, Custom Backends
* Dynamic Secrets
  * S3 Buckets
  * SQL Users
  * Automatic Revocation
* Data Encryption as a Service
  * Encrypt data without storing
  * Applications can encrypt and store in DB
* Leasing/Renewal
  * Automatically revokes after lease is done
  * Renew API
* Revocation
  * Revoke single or trees of secrets
* Policies
  * Capabilities
    * create (POST/PUT)
    * read (GET)
    * update (POST/PUT)
    * delete (DELETE)
    * list (LIST)
    * sudo
    * deny
* Authentication
  * Tokens
* Dynamic Secrets Demo
  * Deploy app to AWS using dynamic IAM
  * Connect app to pgsql using dynamic roles

### Secret Storage

* Sensitive Environment Variables
* Credentials
* API Keys

### Employee Credentials

* Create policies for employees
* Audit employee access
* Revoke employees

### Dynamic Secrets

* Scripts can request one time credentials

### Data Encryption

* Encryption as a Service
* No need to worry about properly encrypting data

## Dev Server

```bash
$ export VAULT_ADDR='http://127.0.0.1:8200'
$ vault server -dev
$ vault status
```

## Hello, World

```bash
$ vault write secret/hello value=world
```

```bash
$ echo -n "brewcore" | vault write secret/password value=-
$ cat data.json
{
    "value": "shhhh"
}
$ vault write secret/password @data.json
$ cat data.txt
lolshh
$ vault write secret/password value=@data.txt
$ vault read -field=value secret/password
$ vault read -format=json secret/password
$ vault delete secret/password
```

## Secrets Backend

* Backends are mounted to Vault
* Generic mounted to `secret/` by default
* Can mount as many backends as you want
* Forwards to Virtual Filesystem

```bash
$ vault mount generic
$ vault mounts
```

```bash
$ vault write secret/password value=test
$ vault read generic/password
```

```bash
$ vault unmount generic
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
$ vault mount database

$ vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="db-readonly, db-readwrite, db-dba" \
    connection_url="postgresql://vault:vault@172.17.0.2:5432/postgres?sslmode=disable"

$ vault write database/roles/db-readonly \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
    renew_statements="ALTER ROLE \"{{name}}\" PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
    default_ttl="1h" \
    max_ttl="24h"

$ vault write database/roles/db-readwrite \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
    renew_statements="ALTER ROLE \"{{name}}\" PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
    default_ttl="1h" \
    max_ttl="24h"

 $ vault write database/roles/db-dba \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH SUPERUSER LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
    revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
    renew_statements="ALTER ROLE \"{{name}}\" PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
    default_ttl="1h" \
    max_ttl="24h"
```

#### Output

```bash
[~/Git/Vault-Presentation] vault mount database
Successfully mounted 'database' at 'database'!

[~/Git/Vault-Presentation] vault write database/config/postgresql \
>     plugin_name=postgresql-database-plugin \
>     allowed_roles="db-readonly, db-readwrite, db-dba" \
>     connection_url="postgresql://vault:vault@172.17.0.2:5432/postgres?sslmode=disable"

The following warnings were returned from the Vault server:
* Read access to this endpoint should be controlled via ACLs as it will return the connection details as is, including passwords, if any.

[~/Git/Vault-Presentation] vault write database/roles/db-readonly \
>     db_name=postgresql \
>     creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
>         GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
>     revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
>     renew_statements="ALTER ROLE \"{{name}}\" PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
>     default_ttl="1h" \
>     max_ttl="24h"
Success! Data written to: database/roles/db-readonly

[~/Git/Vault-Presentation] vault write database/roles/db-readwrite \
>     db_name=postgresql \
>     creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
>         GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
>     revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;"\
>     renew_statements="ALTER ROLE \"{{name}}\" PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
>     default_ttl="1h" \
>     max_ttl="24h"
Success! Data written to: database/roles/db-readwrite

[~/Git/Vault-Presentation] vault write database/roles/db-dba \
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
$ vault write sys/policy/db-readonly rules=@./policy/db-readonly.hcl
$ vault write sys/policy/db-readwrite rules=@./policy/db-readwrite.hcl
$ vault write sys/policy/db-dba rules=@./policy/db-dba.hcl
```

#### Output

```bash
[~/Git/Vault-Presentation/policy] vault write sys/policy/db-readonly rules=@./policy/db-readonly.hcl
Success! Data written to: sys/policy/db-readonly

[~/Git/Vault-Presentation/policy] vault write sys/policy/db-readwrite rules=@./policy/db-readwrite.hcl
Success! Data written to: sys/policy/db-readwrite

[~/Git/Vault-Presentation/policy] vault write sys/policy/db-dba rules=@./policy/db-dba.hcl
Success! Data written to: sys/policy/db-dba
```

### Create Token

```bash
$ vault token-create -policy=db-readonly -period=5m
$ vault token-create -policy=db-readwrite -period=5m
$ vault token-create -policy=db-dba -period=5m
```

#### Output

```bash
[~/Git/Vault-Presentation/policy] vault token-create -policy=db-readonly -period=5m
Key             Value
---             -----
token           200b2645-486c-e07b-3c10-f06e1e51174a
token_accessor  8694ec93-9cec-98a0-87d8-c3310cd6c2dd
token_duration  5m0s
token_renewable true
token_policies  [db-readonly default]

[~/Git/Vault-Presentation/policy] vault token-create -policy=db-readwrite -period=5m
Key             Value
---             -----
token           14ef5dbd-79a3-6634-4fe4-90395132c0d3
token_accessor  9b1f4397-fcb9-a3fd-46f2-2e8a750dcd3e
token_duration  5m0s
token_renewable true
token_policies  [db-readwrite default]

[~/Git/Vault-Presentation/policy] vault token-create -policy=db-dba -period=5m
Key             Value
---             -----
token           ba04bc5e-baf4-c54e-61fc-41926bf678a1
token_accessor  71f51e9c-42a7-454d-28be-4c64182d66d9
token_duration  5m0s
token_renewable true
token_policies  [db-dba default]
```

### Use Token

```bash
$ vault auth
$ vault read database/creds/readonly
```

#### Output

```bash
[~/Git/Vault-Presentation] vault auth
Token (will be hidden):
Successfully authenticated! You are now logged in.
token: 60643e64-a557-8173-8d48-c198b9b3a1c8
token_duration: 257
token_policies: [db-readonly default]

[~/Git/Vault-Presentation] vault read database/creds/db-readonly
Key             Value
---             -----
lease_id        database/creds/db-readonly/143e70b4-e030-982d-b278-c4a446ea6d9c
lease_duration  768h0m0s
lease_renewable true
password        A1a-z2u1v6wtp53u8sys
username        v-token-db-reado-A1a-qx3yppzw8s19rx92-1502811352
```

### PostgreSQL Roles

```bash
postgres=# \du
                                                       List of roles
                    Role name                     |                         Attributes                         | Member of
--------------------------------------------------+------------------------------------------------------------+-----------
 postgres                                         | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 v-root-dba-A1a-q6q42v881yx3qvvt-1502808239       | Superuser                                                 +| {}
                                                  | Password valid until 2017-08-15 10:43:59-04                |
 v-root-readonly-A1a-177xp2t65x9v328r-1502808230  | Password valid until 2017-08-15 11:43:50-04                | {}
 v-token-db-reado-A1a-qx3yppzw8s19rx92-1502811352 | Password valid until 2017-08-15 11:35:52-04                | {}
 vault                                            | Create role                                                | {}
```
