# PowerShell Remote Access

Check whether it is enabled on your local machine with `Enable-PSRemoting`.

## Accessing a Remote Machine

An alias is setup as `psr` and a typical machine can be accessed with `psr -ComputerName 192.168.1.227 -Credential WORKGROUP\username`. If you are in a corporate environment, the `WORKGROUP` will most likely be your _DOMAIN_. **bold**