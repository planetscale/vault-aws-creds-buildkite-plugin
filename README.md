# Vault AWS Credentials Buildkite Plugin

Retrieve time-limited AWS credentials from a Hashicorp Vault [AWS Secrets Backend](https://developer.hashicorp.com/vault/api-docs/secret/aws).

The plugin expects a `VAULT_TOKEN` is already set in the environment. The [vault-oidc-auth](https://github.com/planetscale/vault-oidc-auth-buildkite-plugin)
plugin is an ideal companion to use with this plugin.

## Example

Add the following to your `pipeline.yml`:

```yaml
steps:
  - command: ./run_build.sh
    plugins:
      - planetscale/vault-aws-creds#v1.0.0:
          vault_addr: "https://my-vault-server"   # required
          path: "aws"                             # optional. default "aws"
          role: "my-pipeline"                     # optional. default "$BUILDKITE_PIPELINE_SLUG"
          ttl: "3600s"                            # optional. default "3600s" (NOTE: Vault and AWS have maximum ttl settings that can limit this)
          role_arn: "arn:aws:foo:bar:role/baz"    # optional. default "" (NOTE: Optional if the Vault role only allows a single AWS role ARN; required otherwise.)
          session_name: "my-session"              # optional. default "" (Limited to 64 chars. Vault will dynamically generate a session name if not set.)
          env_prefix: "BUILDKITE_"                # optional. default "" (prefix to add to AWS_ env vars)
```

If authentication is successful the environment variables will be added to the environment:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

Setting the `env_prefix` property will add a prefix to each environment variable name, eg: `BUILDKITE_AWS_ACCESS_KEY_ID`

## Ephemeral Credentials with vault-oidc-auth

This plugin works best when combined with the [vault-oidc-auth](https://github.com/planetscale/vault-oidc-auth-buildkite-plugin) plugin
to provide short-lived credentials for accessing Vault and AWS. Example:

```yaml
steps:
  - command: ./run_build.sh
    plugins:
      - planetscale/vault-oidc-auth#v1.0.0:
          vault_addr: "https://my-vault-server"
      - planetscale/vault-aws-creds#v1.0.0:
          vault_addr: "https://my-vault-server"
```

First, the `vault-oidc-auth` plugin uses a short-lived Buildkite OIDC token to authenticate
to Vault and fetch a `VAULT_TOKEN`.

Next, `vault-aws-creds` uses the `VAULT_TOKEN` to fetch time-limited AWS IAM credentials from Vault.

## Vault Configuration

First, enable the [AWS Secrets Backend](https://developer.hashicorp.com/vault/api-docs/secret/aws). A minimal
configuration using environmental AWS credentials might look like the following. See the docs for
full details on configuring the root IAM credentials.

```console
vault secrets enable -path=aws aws
vault write aws/config/root region=us-east-1
```

Then, create an AWS IAM role for your pipeline through your favorite method and make it available from
Vault by creating and assigning it to role "my-pipeline":

```console
vault write aws/roles/my-pipeline credential_type="assumed_role" role_arns="arn:aws:iam::123456789012/my-pipeline"
```

> NOTE: This plugin has only been tested with the `assumed_role` mode. Other modes may work. Please submit
>       PRs if other modes do not work.

## Developing

To run the linters:

```shell
docker-compose run --rm lint-shellcheck
docker-compose run --rm lint-plugin
```

To run the tests:

```shell
docker-compose run --rm tests
```

## Contributing

1. Fork the repo
2. Make the changes
3. Run the tests
4. Commit and push your changes
5. Send a pull request
