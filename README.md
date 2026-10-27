# install-cfnrain

This GitHub Action installs [cfnrain](https://github.com/awesome-foundation/cfnrain), the community fork of AWS CloudFormation Rain. It runs on Linux, macOS and Windows runners.

Before the install, the action makes sure that the download is safe:

- The archive must match the `checksums.txt` file of the release. If it does not match, the step fails.
- The build provenance must verify with `gh attestation verify`. This proves that the cfnrain release workflow built the archive.

## Usage

```yaml
steps:
  - uses: awesome-foundation/install-cfnrain@v1
    with:
      version: 1.25.2
  - run: cfnrain --version
```

Set `version` to a fixed version, so that a new cfnrain release does not change your pipeline without a review. The default is `latest`.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `version` | `latest` | The cfnrain version, for example `1.25.2`. A `v` prefix is optional. |
| `rain-alias` | `false` | When `true`, the action also puts `rain` on the `PATH`, as a copy of `cfnrain`. |
| `verify-attestation` | `true` | When `false`, the action does not verify the build provenance. It always verifies the checksum. |
| `token` | `${{ github.token }}` | The GitHub token that `gh` uses to download the release. |

## Outputs

| Name | Description |
|------|-------------|
| `cfnrain-bin` | The path to the `cfnrain` binary |
| `version` | The cfnrain version that the action installed |

## Move from install-rain

cfnrain works as a replacement for Rain v1.24.4. If you use `allixsenos/install-rain`, change the step:

```yaml
  # Before
  - uses: allixsenos/install-rain@v1

  # After
  - uses: awesome-foundation/install-cfnrain@v1
    with:
      rain-alias: true
```

With `rain-alias: true`, scripts that call `rain` work without changes. When your scripts call `cfnrain`, remove the input. The cfnrain docs explain the [differences from Rain](https://awesome-foundation.github.io/cfnrain/migrating.html).

## Runner requirements

The action uses `bash` and `gh`. GitHub-hosted runners have both. A self-hosted runner must have them on the `PATH`. Windows runners must also have `unzip`.

## Releases

[release-please](https://github.com/googleapis/release-please) makes the releases from [Conventional Commits](https://www.conventionalcommits.org/) on `main`. Each release moves the `v1` and `v1.x` tags to the new release.

## License

MIT. See [LICENSE](LICENSE).
