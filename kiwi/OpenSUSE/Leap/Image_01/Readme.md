# openSuse Leap 16 - kiwi buil image

## Build image

Manual - for testing.


### Azure profile

```bash
kiwi-ng --debug --profile Azure system build --description . --target-dir ./images/`date +"%Y%m%d-%H%M%S"`/
```


### KVM profile

```bash
kiwi-ng --debug --profile KVM system build --description . --target-dir ./images/`date +"%Y%m%d-%H%M%S"`/
```

