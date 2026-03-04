test_file_env_prod:
  file.managed:
    - name: /tmp/test_file_env
    - contents: |
        # Created by salt state
        prod env
