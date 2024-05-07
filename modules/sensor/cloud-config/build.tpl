#cloud-config

write_files:
  - content: |
      sensor:
        api:
          password: ${api_password}
        license_key: ${license}
        management_interface:
          name: ${mgmt_int}
          wait: true
        monitoring_interface:
          name: ${mon_int}
          wait: true
          health_check:
            port: ${health_port}
            subnet: ${mon_subnet}
            gateway: ${mon_gateway}
        kubernetes:
          allow_ports:
%{ for probe in probe_ranges ~}
            - protocol: tcp
              port: ${health_port}
              net: ${probe}
%{ endfor ~}

    owner: root:root
    path: /etc/corelight/corelightctl.yaml
    permissions: '0644'

runcmd:
  - corelightctl sensor bootstrap -v
  - corelightctl sensor deploy -v
