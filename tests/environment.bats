#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"

# export VAULT_STUB_DEBUG=/dev/tty

@test "vault_addr is not set" {
  export BUILDKITE_PIPELINE_SLUG="foo"

  run bash -c "$PWD/hooks/environment && env"
  assert_success
  assert_output --partial "Skipping"

  unset BUILDKITE_PIPELINE_SLUG
}

@test "successful creds retrieval with defaults" {
  export BUILDKITE_PIPELINE_SLUG="foo"
  export BUILDKITE_PLUGIN_VAULT_AWS_CREDS_VAULT_ADDR="http://vault:8200"

  stub vault \
    'read -format=json aws/sts/foo ttl=3600s : cat tests/fixtures/vault-post-sts.json'

  run bash -c "source $PWD/hooks/environment && env | sort"
  assert_success
  assert_output --partial "AWS_ACCESS_KEY_ID=AKFOO"
  assert_output --partial "AWS_SECRET_ACCESS_KEY=abc"
  assert_output --partial "AWS_SESSION_TOKEN=Fwozxxx"

  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_AWS_CREDS_VAULT_ADDR
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
}

@test "successful creds retrieval with overrides" {
  export BUILDKITE_PIPELINE_SLUG="foo"
  export BUILDKITE_PLUGIN_VAULT_AWS_CREDS_VAULT_ADDR="http://vault:8200"
  export BUILDKITE_PLUGIN_VAULT_AWS_CREDS_PATH="aws-creds"
  export BUILDKITE_PLUGIN_VAULT_AWS_CREDS_ROLE="bar"
  export BUILDKITE_PLUGIN_VAULT_AWS_CREDS_TTL="7200s"
  export BUILDKITE_PLUGIN_VAULT_AWS_CREDS_ROLE_ARN="aws:arn:iam:123456789012:role/bar"
  export BUILDKITE_PLUGIN_VAULT_AWS_CREDS_SESSION_NAME="my-sesh"
  export BUILDKITE_PLUGIN_VAULT_AWS_CREDS_ENV_PREFIX="BUILDKITE_"

  stub vault \
    'read -format=json aws-creds/sts/bar ttl=7200s role_arn=aws:arn:iam:123456789012:role/bar role_session_name=my-sesh : cat tests/fixtures/vault-post-sts.json'

  run bash -c "source $PWD/hooks/environment && env | sort"
  assert_success
  assert_output --partial "BUILDKITE_AWS_ACCESS_KEY_ID=AKFOO"
  assert_output --partial "BUILDKITE_AWS_SECRET_ACCESS_KEY=abc"
  assert_output --partial "BUILDKITE_AWS_SESSION_TOKEN=Fwozxxx"

  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_VAULT_AWS_CREDS_VAULT_ADDR
  unset BUILDKITE_PLUGIN_VAULT_AWS_CREDS_PATH
  unset BUILDKITE_PLUGIN_VAULT_AWS_CREDS_ROLE
  unset BUILDKITE_PLUGIN_VAULT_AWS_CREDS_TTL
  unset BUILDKITE_PLUGIN_VAULT_AWS_CREDS_ROLE_ARN
  unset BUILDKITE_PLUGIN_VAULT_AWS_CREDS_SESSION_NAME
  unset BUILDKITE_PLUGIN_VAULT_AWS_CREDS_ENV_PREFIX

  unset BUILDKITE_AWS_ACCESS_KEY_ID
  unset BUILDKITE_AWS_SECRET_ACCESS_KEY
  unset BUILDKITE_AWS_SESSION_TOKEN
}
