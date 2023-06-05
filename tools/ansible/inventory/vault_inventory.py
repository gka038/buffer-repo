from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = r'''
    name: vault_inventory
    plugin_type: inventory
    short_description: Returns Ansible inventory from Vault
    description: Returns Ansible inventory from Vault
    extends_documentation_fragment:
        - inventory_cache
    options:
      plugin:
          description: Name of the plugin
          required: true
          choices: ['vault_inventory']
'''

import hvac
import yaml
import os
from time import time
import json
from pathlib import Path
from ansible.plugins.inventory import BaseInventoryPlugin, Cacheable, Constructable

GROUP_VARS = yaml.safe_load(Path('group_vars/all.yml').read_text())

OPENVPN_MOUNT_POINT = 'openvpn-ip'
OPENVPN_FOLDERS = 'bastions'

VAULT_ADDRESS = GROUP_VARS['VAULT_URL']
VAULT_PORT = GROUP_VARS['VAULT_PORT']
VAULT_RO_BOT_ROLE_ID = GROUP_VARS['VAULT_RO_BOT_ROLE_ID']
VAULT_RO_BOT_SECRET_ID = GROUP_VARS['VAULT_RO_BOT_SECRET_ID']

client = hvac.Client( url="{}:{}".format(VAULT_ADDRESS,VAULT_PORT))
client.auth.approle.login(
    role_id=VAULT_RO_BOT_ROLE_ID,
    secret_id=VAULT_RO_BOT_SECRET_ID,
)

class InventoryModule(BaseInventoryPlugin, Constructable, Cacheable):
    
    NAME = 'vault_inventory'

    def __init__(self):
        """Main execution path"""
        self.cache_path = "./inventory/"
        self.cache_max_age = 86400
        # Manage cache
        self.cache_filename = self.cache_path + "/ansible-vault-inventory.cache"
        self.cache_refreshed = False
        self.results = {}

    def _get_Ip_addr_vault(self, ipPath):
        try:
            response = client.secrets.kv.v2.read_secret_version(
                mount_point=OPENVPN_MOUNT_POINT,
                path=ipPath,
            )
        except hvac.exceptions.InvalidPath:
            response = {'data': {'data': {'ip': 'empty'}}}

        return response['data']['data']

    def _get_bastions_list_vault(self, mount_point, path):
        response = client.secrets.kv.v2.list_secrets(
            mount_point=mount_point,
            path=path
        )
        return response['data']['keys']

    def get_inventory(self):
        bastion_conf = {}
        for bhost in self._get_bastions_list_vault(OPENVPN_MOUNT_POINT, OPENVPN_FOLDERS):
            bastion_conf[bhost] = self._get_Ip_addr_vault(OPENVPN_FOLDERS + "/" + bhost)
        return bastion_conf

    def populate(self, results):
        self.inventory.add_group("bastion")
        self.inventory.set_variable("bastion", 'ansible_user', "spryker-admin")
        self.inventory.set_variable("bastion", 'ansible_port', "22")
        for h in results:
            self.inventory.add_host(h,"bastion")
            self.inventory.set_variable(h, 'ansible_host', results[h]["ip"])
            if "EASYRSA_CERT_EXPIRE" in results[h]:
                self.inventory.set_variable(h, 'EASYRSA_CERT_EXPIRE', results[h]["EASYRSA_CERT_EXPIRE"])
            else:
                self.inventory.set_variable(h, 'EASYRSA_CERT_EXPIRE', GROUP_VARS["default_easyrsa_cert_expire"])
            if "vpn_inactivity_timeout" in results[h]:
                self.inventory.set_variable(h, 'vpn_inactivity_timeout', results[h]["vpn_inactivity_timeout"])
            else:
                self.inventory.set_variable(h, 'vpn_inactivity_timeout', GROUP_VARS["default_vpn_inactivity_timeout"])

    ###########################################################################
    # Cache Management
    ###########################################################################

    def is_cache_valid(self):
        """Determines if the cache files have expired, or if it is still valid"""
        if os.path.isfile(self.cache_filename):      
            mod_time = os.path.getmtime(self.cache_filename)           
            current_time = time()
            if (mod_time + self.cache_max_age) > current_time:
                return True
        return False

    def load_from_cache(self):
        """Reads the data from the cache file and assigns it to member variables as Python Objects"""
        try:
            with open(self.cache_filename, "r") as cache:
                json_data = cache.read()
            data = json.loads(json_data)
        except IOError:
            data = {"data": {}}
        self.data = data["data"]

    def write_to_cache(self):
        """Writes data in JSON format to a file"""
        data = {"data": self.data}
        json_data = json.dumps(data, indent=2)

        with open(self.cache_filename, "w") as cache:
            cache.write(json_data)

    def parse(self, inventory, loader, path, cache=True):
        
        super(InventoryModule, self).parse(inventory, loader, path, cache=cache)
        self._read_config_data(path)  # This also loads the cache
        self.load_cache_plugin()
        # cache_key = self.get_cache_key(path)

        # cache may be True or False at this point to indicate if the inventory is being refreshed
        # get the user's cache option too to see if we should save the cache if it is changing
        user_cache_setting = self.get_option('cache')

        # read if the user has caching enabled and the cache isn't being refreshed
        attempt_to_read_cache = user_cache_setting and cache
        # update if the user has caching enabled and the cache is being refreshed; update this value to True if the cache has expired below
        cache_needs_update = user_cache_setting and not cache
        # attempt to read the cache if inventory isn't being refreshed and the user has caching enabled
        if attempt_to_read_cache:
            try:
                if self.is_cache_valid(): 
                    self.load_from_cache()
                    if len(self.data) == 0:
                        print(len(self.data))
                        cache_needs_update = True
                else:   
                    cache_needs_update = True        
            except KeyError:
                # This occurs if the cache_key is not in the cache or if the cache_key expired, so the cache needs to be updated
                cache_needs_update = True
        if not attempt_to_read_cache or cache_needs_update:
            # parse the provided inventory source
            self.results = self.get_inventory()
        if cache_needs_update:
            self.data = self.results
            self.write_to_cache()
        self.populate(self.data)
