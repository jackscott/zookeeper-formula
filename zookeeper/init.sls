{%- from 'zookeeper/settings.sls' import zk with context %}

zookeeper:
  group.present:
    - name: {{ zk.user }}
  user.present:
    - order: 3
    - name: {{ zk.user }}
    - fullname: "Zookeeper Server"
    - gid_from_name: True
    - system: true
    - createhome: false
    - require:
        - group: zookeeper
    - groups:
        - {{ zk.user }}
        
zk-directories:
  file.directory:
    - user: {{ zk.user }}
    - group: {{ zk.user }}
    - mode: 755
    - makedirs: True
    - names:
      - /var/run/zookeeper
      - /var/lib/zookeeper
      - /var/log/zookeeper
    - require:
        - user: zookeeper
          
install-zookeeper-dist:
  cmd.run:
    - name: curl -L '{{ zk.source_url }}' | tar xz --no-same-owner
    - cwd: {{ zk.prefix }}
    - unless: test -d {{ zk.real_home }}/lib
    - user: root
  alternatives.install:
    - name: zookeeper-home-link
    - link: {{ zk.alt_home }}
    - path: {{ zk.real_home }}
    - priority: 30
    - require:
      - cmd: install-zookeeper-dist

