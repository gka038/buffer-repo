import random
import string
from dataclasses import dataclass
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization


@dataclass
class Generator:
    pass


class PublicPrivateKeyGenerator(Generator):
    key: rsa.RSAPrivateKey

    def __init__(self):
        self.key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
        )

    def private_key(self) -> str:
        return self.key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption()
        ).decode("utf-8").replace("\n", "")

    def public_key(self) -> str:
        return self.key.public_key().public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo,
        ).decode("utf-8").replace("\n", "")


class RandomStringGenerator(Generator):
    characters = string.ascii_letters + string.digits
    value = ""

    def __init__(self, length: int):
        chars = random.choices(self.characters, k=length)
        self.value = self.value.join(chars)


class OAuthClientConfigGenerator(RandomStringGenerator):
    def __init__(self, length: int):
        super().__init__(length=length)
        self.value = '[{{"identifier":"frontend","secret":"{}","isConfidential":true,"name":"Customer ' \
                     'client","redirectUri":null,"isDefault":true}}]'.format(self.value)


class PatternRandomStringGenerator(RandomStringGenerator):
    def __init__(self, pattern: str):
        super().__init__(length=8)
        self.value = "{}-{}".format(pattern, self.value)
