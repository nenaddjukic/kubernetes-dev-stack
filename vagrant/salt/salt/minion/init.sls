include:
   - minion.flannel
   - minion.docker
   - minion.kubernetes

{% set nfs_ip = salt['grains.get']('nfs_ip') %}

dekstroza-nfs-server:
  host.present:
    - ip: {{ nfs_ip }}
    - names:
      - nfs
      - nfs.{{ pillar['dns_domain'] }}

permissive:
    selinux.mode

firewalld:
  service.dead:
    - name: firewalld
    - enable: false

flannel-running:
  service.running:
    - name: flanneld
    - watch:
      - file: /etc/sysconfig/flanneld
    - require:
      - file: /etc/sysconfig/flanneld

docker-running:
  service.running:
    - name: docker
    - require:
      - file: docker-config
      - file: docker-network-config
      - service: flanneld

kubelet-running:
  service.running:
    - name: kubelet
    - watch:
      - file: /etc/kubernetes/config
      - file: /etc/kubernetes/kubelet
    - require:
      - service: docker
      - file: /etc/kubernetes/config
      - file: /etc/kubernetes/kubelet

kube-proxy-running:
  service.running:
    - name: kube-proxy
    - require:
      - service: kubelet

create-routing-scripts:
  cmd.script:
    - source: salt://minion/post-boot-scripts/configure.sh
    - user: root
    - template: jinja
    - require:
      - service: kube-proxy
