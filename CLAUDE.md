# Scribe

The plugin itself is `scribe/`. The `.claude-plugin/marketplace.json` at the root is only the catalog that points at it.

## Releasing

The version is a date, `YY.MMDD.N`, where `N` counts releases within that same day. `scribe/.claude-plugin/plugin.json` owns it and the README quotes it twice, in the badge and in Status.

Do not edit those by hand. Run it:

```bash
node scripts/version.mjs
```

It stamps today, bumps `N` if today already shipped, writes every site, and tells you if a site still holds the old number. Commit the result with the change it is releasing.

A release is a merge to `main`. Stamp once per PR, in its last commit, never per commit: a branch with eight commits ships one version.
