Manage selinux mode:
  selinux.mode:
    - name: permissive

Install httpd package:
  pkg.installed:
    - name: httpd
    - require:
      - selinux: Manage selinux mode

Manage httpd service:
  service.running:
    - name: httpd
    - enable: True
    - watch:
      - pkg: Install httpd package

Manage cats-or-dogs firewalld service:
  firewalld.service:
    - name: cats-or-dogs
    - ports:
      - 80/tcp
    - require:
      - service: Manage httpd service

Manage cats-or-dogs firewalld zone:
  firewalld.present:
    - name: cats-or-dogs
    - services:
      - cats-or-dogs
    - sources:
{%- for mac, properties in salt.grains.get('meta-data:network:interfaces:macs', {}).items() %}
  {%- if properties['device-number'] == 0 %}
    {%- for cidr in properties['vpc-ipv4-cidr-blocks'].split('\n') %}
      - {{ cidr }}
    {%- endfor %}
  {%- endif %}
{%- endfor %}
    - require:
      - firewalld: Manage cats-or-dogs firewalld service

Manage /var/www/html/index.html:
  file.managed:
    - name: /var/www/html/index.html
    - source: salt://{{ tpldir }}/index.html.jinja
    - template: jinja
    - mode: 0644
    - user: root
    - group: root
    - context:
        base_url: {{ grains['cats-or-dogs']['base_url'] }}
        az: {{ grains['meta-data']['placement']['availability-zone'] }}
        cats_az: {{ grains['cats-or-dogs']['cats_az'] }}
    - require:
      - pkg: Install httpd package
