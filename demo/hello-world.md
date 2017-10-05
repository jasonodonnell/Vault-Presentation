```bash
make build
export VAULT_ADDR='http://127.0.0.1:8200'
ROOT_TOKEN=$(docker logs vault-server 2>&1 | grep "Root Token" | awk '{print $3}')
vault auth ${ROOT_TOKEN?}
vault status

vault write secret/hello value=world
vault read secret/hello

echo -n "brewcore" | vault write secret/password value=-
vault read secret/password


cat data.json
vault write secret/password @data.json
vault read -field=value secret/password

cat data.txt
vault write secret/password value=@data.txt
vault read -field=value secret/password

vault read -format=json secret/password
vault delete secret/password
```
