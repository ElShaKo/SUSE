test_file_env_dev:
  file.managed:
    - name: /tmp/test_file_env
    - contents: |
        # Created by salt state
        dev env
