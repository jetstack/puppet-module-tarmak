class tarmak::worker {
  include ::tarmak
  require ::vault_client

  $proxy_base_path = "${::tarmak::kubernetes_ssl_dir}/kube-proxy"
  vault_client::cert_service { 'kube-proxy':
    base_path   => $proxy_base_path,
    common_name => 'system:kube-proxy',
    role        => "${::tarmak::cluster_name}/pki/${::tarmak::kubernetes_ca_name}/sign/kube-proxy",
    uid         => $::tarmak::kubernetes_uid,
    require     => [
      User[$::tarmak::kubernetes_user],
      Class['vault_client']
    ],
    exec_post   => [
      "-${::tarmak::systemctl_path} --no-block try-restart kube-proxy.service"
    ],
  }

  $kubelet_base_path = "${::tarmak::kubernetes_ssl_dir}/kubelet"
  vault_client::cert_service { 'kubelet':
    base_path   => $kubelet_base_path,
    common_name => "system:node:${::fqdn}",
    role        => "${::tarmak::cluster_name}/pki/${::tarmak::kubernetes_ca_name}/sign/kubelet",
    uid         => $::tarmak::kubernetes_uid,
    alt_names   => ["${::fqdn}"],
    require     => [
      User[$::tarmak::kubernetes_user],
      Class['vault_client']
    ],
    exec_post   => [
      "-${::tarmak::systemctl_path} --no-block try-restart kubelet.service"
    ],
  }

  class { 'kubernetes::kubelet':
      ca_file          => "${kubelet_base_path}-ca.pem",
      key_file         => "${kubelet_base_path}-key.pem",
      cert_file        => "${kubelet_base_path}.pem",
      client_ca_file   => "${kubelet_base_path}-ca.pem",
      systemd_after    => ['kubelet-cert.service'],
      systemd_requires => ['kubelet-cert.service'],
  }

  class { 'kubernetes::proxy':
      ca_file          => "${proxy_base_path}-ca.pem",
      key_file         => "${proxy_base_path}-key.pem",
      cert_file        => "${proxy_base_path}.pem",
      systemd_after    => ['kube-proxy-cert.service'],
      systemd_requires => ['kube-proxy-cert.service'],
  }

  class { 'kubernetes::worker':

  }

}
