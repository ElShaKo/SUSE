test_file:
  file.managed:
    - name: /tmp/test_file
    - contents: |
        # Created by salt state
        xxx
