{% set p  = salt['pillar.get']('zookeeper', {}) %}
{% set pc = p.get('config', {}) %}
{% set g  = salt['grains.get']('zookeeper', {}) %}
{% set gc = g.get('config', {}) %}

{%- set prefix       = p.get('prefix', '/usr/lib') %}
{%- set java_home    = salt['grains.get']('java_home', salt['pillar.get']('java_home', '/usr/lib/java')) %}


{%- set log_level         = gc.get('log_level', pc.get('log_level', 'INFO')) %}
{%- set version           = g.get('version', p.get('version', '3.4.6')) %}
{%- set version_name      = 'zookeeper-' + version %}
{%- set default_url       = 'http://apache.osuosl.org/zookeeper/' + version_name + '/' + version_name + '.tar.gz' %}
{%- set source_url        = g.get('source_url', p.get('source_url', default_url)) %}
# bind_address is only supported as a grain, because it has to be host-specific
{%- set bind_address      = gc.get('bind_address', '0.0.0.0') %}
{%- set data_dir          = gc.get('data_dir', pc.get('data_dir', '/var/lib/zookeeper/data')) %}
{%- set port              = gc.get('port', pc.get('port', '2181')) %}
{%- set jmx_port          = gc.get('jmx_port', pc.get('jmx_port', '2183')) %}
{%- set snap_count        = gc.get('snap_count', pc.get('snap_count', None)) %}
{%- set snap_retain_count = gc.get('snap_retain_count', pc.get('snap_retain_count', 3)) %}
{%- set purge_interval    = gc.get('purge_interval', pc.get('purge_interval', None)) %}
{%- set max_client_cnxns  = gc.get('max_client_cnxns', pc.get('max_client_cnxns', None)) %}
{%- set data_log_dir      = gc.get('data_log_dir', pc.get('data_log_dir', None)) %}

#
# JVM options - just follow grains/pillar settings for now
#
# set in - zookeeper:
#          - config:
#            - max_perm_size:
#            - max_heap_size:
#            - initial_heap_size:
#            - jvm_opts:
#
{%- set max_perm_size     = gc.get('max_perm_size', pc.get('max_perm_size', 128)) %}
{%- set max_heap_size     = gc.get('max_heap_size', pc.get('max_heap_size', 1024)) %}
{%- set initial_heap_size = gc.get('initial_heap_size', pc.get('initial_heap_size', 256)) %}
{%- set jvm_opts          = gc.get('jvm_opts', pc.get('jvm_opts', None)) %}  

{%- set alt_config   = salt['grains.get']('zookeeper:config:directory', '/etc/zookeeper/conf') %}
{%- set real_config  = alt_config + '-' + version %}
{%- set alt_home     = prefix + '/zookeeper' %}
{%- set real_home    = alt_home + '-' + version %}
{%- set real_config_src  = real_home + '/conf' %}
{%- set real_config_dist = alt_config + '.dist' %}

{%- set hosts_target = g.get('hosts_target', p.get('hosts_target', 'roles:zookeeper')) %}
{%- set targeting_method = g.get('targeting_method', p.get('targeting_method', 'grain')) %}

# calling .keys() will throw an exception on an empty dict, not sure if this is too aggressive or not
# also unsure if the `sort` is necessary, we do want the nodes id's to be uniform across all machines though
{%- set zookeeper_hosts = salt['mine.get'](hosts_target, 'network.ip_addrs', targeting_method).keys()|sort %}
{%- set zookeeper_host_num = zookeeper_hosts|length %}

{%- if zookeeper_host_num == 0 %}
# this will fail to even render but provide a hint as to what's wrong
{{ 'No zookeeper nodes are defined (you need to set roles:zookeeper at least for one node in your cluster' }}
{%- elif zookeeper_host_num is odd %}
# for 1, 3, 5 ... nodes just return the list
{%- set node_count = zookeeper_host_num %}
{%- elif zookeeper_host_num is even %}
# for 2, 4, 6 ... nodes return (n -1)
{%- set node_count = zookeeper_host_num - 1 %}
{%- endif %}

# given a hostname, return a host:port formatted string
{%- macro zk_server(hostname) %}
{{ "%s:%d"|format(hostname, port) }}
{%- endmacro %}
# comma separated string of hostnames and ports
{%- set connection_string = zookeeper_hosts|map('zk_server')|join(",") %}

# build up a map where {hostname => int}, used later on to create `myid`
{%- set zookeepers_with_ids = {} %}
{%- for i in range(node_count) %}
{%- do zookeepers_with_ids.update({zookeeper_hosts[i] :  '{0:d}'.format(i)  %}
{%- endfor %}

# return either the id of the host or an empty string
{%- set myid = zookeepers_with_ids.get(grains.id, '') %}

{%- set zk = {} %}
{%- do zk.update( { 'user': g.get('user', p.get('user')),
                    'version' : version,
                    'version_name': version_name,
                    'source_url': source_url,
                    'myid': myid,
                    'prefix' : prefix,
                    'alt_config' : alt_config,
                    'real_config' : real_config,
                    'alt_home' : alt_home,
                    'real_home' : real_home,
                    'real_config_src' : real_config_src,
                    'real_config_dist' : real_config_dist,
                    'java_home' : java_home,
                    'port': port,
                    'jmx_port': jmx_port,
                    'bind_address': bind_address,
                    'data_dir': data_dir,
                    'snap_count': snap_count,
                    'snap_retain_count': snap_retain_count,
                    'purge_interval': purge_interval,
                    'max_client_cnxns': max_client_cnxns,
                    'myid_path': data_dir + '/myid',
                    'zookeeper_host' : zookeeper_host,
                    'zookeepers' : zookeepers,
                    'zookeepers_with_ids' : zookeepers_with_ids.values(),
                    'connection_string' : connection_string,
                    'initial_heap_size': initial_heap_size,
                    'max_heap_size': max_heap_size,
                    'max_perm_size': max_perm_size,
                    'jvm_opts': jvm_opts,
                    'log_level': log_level,
                    'data_log_dir': data_log_dir
                 }) %}





