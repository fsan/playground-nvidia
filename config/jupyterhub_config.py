# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

from jupyter_core.paths import jupyter_data_dir
import subprocess
import os
import errno
import stat
import yaml


##############
# helpers

def get_environment(fname):
    with open(fname) as file:
        entries = yaml.load(file, Loader=yaml.FullLoader)
    return entries

def get(config, strkeys, RaiseOnMissingKey=True):
    keys = strkeys.split(',')
    node = config
    for k in keys:
        if node is not None:
            node = node.get(k, None)
            if RaiseOnMissingKey:
                if node is None:
                    raise KeyError('Missing key %s' % k)
        else:
            if RaiseOnMissingKey:
                if node is None:
                    raise KeyError('Missing node for %s' % k)

    return node

def get_server(config):
    server = get(config, 'authentication,server')
    address = get(server, 'address', RaiseOnMissingKey=False)
    port = get(server, 'port', RaiseOnMissingKey=False)
    use_ssl = get(server,'use_ssl', RaiseOnMissingKey=False)
    return address, port, use_ssl

def get_type(config):
    return get(config, 'authentication,type')

def get_enabled(config):
    return (get(config, 'authentication,enabled') == True)

def get_allowed_groups(config):
    return get(config, 'authentication,groups,allowed_groups', RaiseOnMissingKey=False)

def get_allowed_admin_groups(config):
    return get(config, 'authentication,groups,allowed_admin_groups', RaiseOnMissingKey=False)

def get_bind_dn_template(config):
    return get(config, 'authentication,authenticator,bind_dn_template')

def get_bind_cn_template(config):
    return get(config, 'authentication,authenticator,bind_cn_template')

def get_user_search_base(config):
    return get(config, 'authentication,authenticator,user_search_base')

def get_user_attribute(config):
    return get(config, 'authentication,authenticator,user_attribute')

def get_lookup_cn(config):
    return get(config, 'authentication,authenticator,lookup_cn')

def get_lookup_cn_username(config):
    return get(config, 'authentication,authenticator,use_lookup_cn_username')

def get_lookup_cn_user_cn_attribute(config):
    return get(config, 'authentication,authenticator,lookup_cn_user_cn_attribute')



#############
env = get_environment('/etc/jupyter/environment.yaml')

c = get_config()
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False
c.NotebookApp.token = ''
c.NotebookApp.password = ''

# https://github.com/jupyter/notebook/issues/3130
c.FileContentsManager.delete_to_trash = False

# Generate a self-signed certificate
if 'GEN_CERT' in os.environ:
    dir_name = jupyter_data_dir()
    pem_file = os.path.join(dir_name, 'notebook.pem')
    try:
        os.makedirs(dir_name)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(dir_name):
            pass
        else:
            raise
    # Generate a certificate if one doesn't exist on disk
    subprocess.check_call(['openssl', 'req', '-new',
                           '-newkey', 'rsa:2048',
                           '-days', '365',
                           '-nodes', '-x509',
                           '-subj', '/C=XX/ST=XX/L=XX/O=generated/CN=generated',
                           '-keyout', pem_file,
                           '-out', pem_file])
    # Restrict access to the file
    os.chmod(pem_file, stat.S_IRUSR | stat.S_IWUSR)
    c.NotebookApp.certfile = pem_file

c.Spawner.default_url = '/lab'
c.JupyterHub.spawner_class = 'jupyterhub.spawner.SimpleLocalProcessSpawner'

if get_type(env) == 'active_directory' and get_enabled(env):
    c.JupyterHub.authenticator_class = 'ldapauthenticator.LDAPAuthenticator'
    c.LDAPAuthenticator.server_address, _, c.LDAPAuthenticator.use_ssl,  = get_server(env)

    allowed_groups = get_allowed_groups(env)
    allowed_admin_groups = get_allowed_admin_groups(env)

    if allowed_groups:
        c.LDAPAuthenticator.allowed_groups = allowed_groups
    if allowed_admin_groups:
        c.LDAPAuthenticator.allowed_admin_groups = allowed_admin_groups


    c.LDAPAuthenticator.bind_dn_template = get_bind_dn_template(env)
    c.LDAPAuthenticator.bind_cn_template = get_bind_cn_template(env)
    c.LDAPAuthenticator.user_search_base = get_user_search_base(env)

    c.LDAPAuthenticator.lookup_cn = get_lookup_cn(env)
    c.LDAPAuthenticator.user_attribute = get_user_attribute(env)
    c.LDAPAuthenticator.lookup_cn_user_cn_attribute= get_lookup_cn_user_cn_attribute(env)

    c.LDAPAuthenticator.use_lookup_cn_username = False
    c.LDAPAuthenticator.lookup_cn_user_cn_search_filter = '({login_attr}={login})'
    c.LDAPAuthenticator.escape_userdn = False

