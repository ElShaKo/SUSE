test_file_env_test:
  file.managed:
    - name: /tmp/test_file_env
    - contents: |
        # Created by salt state
        test env
