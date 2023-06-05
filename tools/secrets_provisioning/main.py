import sys
import hvac
import os
import re
import urllib3
from dataclasses import dataclass
from generator import *


@dataclass
class Secret:
    secret_name: str
    secret_key: str
    generated_value: str
    mount_point: str

    def __init__(self, secret_name: str, generated_value: str, secret_key: str = "value", mount_point: str = "kv"):
        super().__init__()
        self.secret_name = secret_name
        self.secret_key = secret_key
        self.generated_value = generated_value
        self.mount_point = mount_point

    def vault_key(self, environment_prefix: str) -> str:
        return "{}/{}".format(environment_prefix, self.secret_name)

    def value(self) -> str:
        return self.generated_value

    def __str__(self):
        return "{} -> {}".format(self.secret_key, self.generated_value)


# Disable SSL verification
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def get_or_create_secret(path: str, key: str, value: str, mount_point: str = "kv"):
    """
    Checks if a secret by a key exists in Vault and creates a new one if it does not.

    Args:
        path (str): The path to the secret in Vault.
        key (str): The key for the secret.
        value (str): A function that generates a new key if the secret does not exist.
        mount_point (str): A mount point where to save this secret.
    """
    # Connect to Vault
    client = hvac.Client(verify=False)

    try:
        secret = client.secrets.kv.v2.read_secret_version(
            mount_point=mount_point,
            path=path,
            raise_on_deleted_version=False  # suppress deprecation warning
        )
        secret = secret['data']['data']
        # Check if the key exists in the secret
        if key not in secret:
            # The key does not exist in the secret, will add it
            print("Key {} does not exist in secret {}, adding...".format(key, path))
            secret[key] = value
            client.secrets.kv.v2.create_or_update_secret(
                mount_point=mount_point,
                path=path,
                secret=secret
            )
    except hvac.v1.exceptions.InvalidPath:
        # Most likely the secret does not exist, create one
        print("Creating secret {}".format(path))
        client.secrets.kv.v2.create_or_update_secret(
            mount_point=mount_point,
            path=path,
            secret={key: value}
        )


def main(customer_name: str, customer_project: str, environment_name: str):
    full_env_name = "{}-{}-{}".format(customer_name, customer_project, environment_name)
    vault_prefix = "Customers/{}/{}/{}/".format(customer_name, customer_project, environment_name)

    oauth_keypair = PublicPrivateKeyGenerator()
    broker_user = PatternRandomStringGenerator(pattern="spryker")
    rabbitmqpass = RandomStringGenerator(length=32).value
    ssm_password = RandomStringGenerator(length=32)

    secrets = [
        Secret(secret_name=vault_prefix + "spryker_secrets", secret_key="SPRYKER_OAUTH_KEY_PRIVATE",
               generated_value=oauth_keypair.private_key()),
        Secret(secret_name=vault_prefix + "spryker_secrets", secret_key="SPRYKER_OAUTH_KEY_PUBLIC",
               generated_value=oauth_keypair.public_key()),
        Secret(secret_name=vault_prefix + "spryker_secrets", secret_key="SPRYKER_OAUTH_ENCRYPTION_KEY",
               generated_value=RandomStringGenerator(length=64).value),
        Secret(secret_name=vault_prefix + "spryker_secrets", secret_key="SPRYKER_OAUTH_CLIENT_IDENTIFIER",
               generated_value=RandomStringGenerator(length=24).value),
        Secret(secret_name=vault_prefix + "spryker_secrets", secret_key="SPRYKER_OAUTH_CLIENT_SECRET",
               generated_value=RandomStringGenerator(length=64).value),
        Secret(secret_name=vault_prefix + "spryker_secrets", secret_key="SPRYKER_ZED_REQUEST_TOKEN",
               generated_value=RandomStringGenerator(length=64).value),
        Secret(secret_name=vault_prefix + "spryker_secrets", secret_key="SPRYKER_URI_SIGNER_SECRET_KEY",
               generated_value=RandomStringGenerator(length=64).value),
        Secret(secret_name=vault_prefix + "spryker_secrets", secret_key="SPRYKER_OAUTH_CLIENT_CONFIGURATION",
               generated_value=OAuthClientConfigGenerator(length=64).value),

        Secret(secret_name="ec2/ansible-config/" + full_env_name, secret_key="vault_pass", mount_point="cloud",
               generated_value=ssm_password.value),
        Secret(secret_name=vault_prefix + "ssm_ansible_password", generated_value=ssm_password.value),
        Secret(secret_name=vault_prefix + "default_credentials_token",
               generated_value=RandomStringGenerator(length=32).value),
        Secret(secret_name=vault_prefix + "broker_api_user", generated_value=broker_user.value),
        Secret(secret_name=vault_prefix + "broker_api_user_password",
               generated_value=rabbitmqpass),
        Secret(secret_name=vault_prefix + "broker_user", generated_value=broker_user.value),
        Secret(secret_name=vault_prefix + "broker_user_password",
               generated_value=rabbitmqpass),
        Secret(secret_name=vault_prefix + "rabbitmq_default_user", generated_value=broker_user.value),
        Secret(secret_name=vault_prefix + "rabbitmq_default_pass",
               generated_value=rabbitmqpass),

        Secret(secret_name=vault_prefix + "master_username",
               generated_value=PatternRandomStringGenerator(pattern="spryker").value),
    ]

    for secret in secrets:
        get_or_create_secret(path=secret.secret_name, key=secret.secret_key, value=secret.generated_value,
                             mount_point=secret.mount_point)


def extract_names(file: str) -> (str, str, str):
    customer_name = ""
    customer_project = ""
    environment_name = ""
    with open(file, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("project_owner"):
                customer_name = line.split("=")[-1].strip().strip('"')
            elif line.startswith("customer_project"):
                customer_project = line.split("=")[-1].strip().strip('"')
            elif line.startswith("env_type"):
                environment_name = line.split("=")[-1].strip().strip('"')
    return customer_name, customer_project, environment_name


if __name__ == "__main__":
    main(*extract_names(os.getenv("DIR", ".") + "/config/common/spryker.hcl"))
