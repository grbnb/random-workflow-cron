# GitHub Action for workflow cron

[README](README.md) | [中文文档](README_zh.md)

The GitHub Actions for pushing to GitHub repository workflows cron changes authorizing using GitHub token.

With ease:

- Used for GitHub actions workflow with irregular scheduling and running
- Automatically generate random cron expressions, only for `hour` and `minute` random generation

## Usage

### Example Workflow file

Randomly modify the `cron` expression under the `schedule` in the current branch workflow file (modify oneself), and keep the historical commit message of files except for workflow files:

```yaml
name: 'random-cron'

on:
  schedule:
    - cron: '0 0 */17 * *'
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Random Cron
        uses: grbnb/random-workflow-cron@v2
        with:
          github_token: ${{ secrets.PAT }}
          keep_history: true
```

Randomly modify the `cron` under the `schedule` in the `dev` workflow file `ci. yml` of other branches in the current warehouse (modifying other files): [Not recommended], and keep the historical commit message of files except for workflow files:

```yaml
name: 'random-cron'

on:
  schedule:
    - cron: '0 0 */17 * *'
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Random Cron
        uses: grbnb/random-workflow-cron@v2
        with:
          workflow_name: ".github/workflows/ci.yml"
          github_token: ${{ secrets.PAT }}
          ref_branch: dev
          keep_history: true
```

Set the random hour range to `1-21` [UTC+8 time zone], running only 7 times a day every 15 days, but not immediately pushing and commit to the repository. This means that there are push operations in the steps after the workflow file, avoiding multiple push operations!!!

```yml
name: 'random-cron'

on:
  schedule:
    - cron: '0 0 */17 * *'
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.PAT }}
          fetch-depth: 2
      
      - name: Random Cron
        uses: grbnb/random-workflow-cron@v1
        with:
          push_switch: false
          time_zone: "UTC+8"
          hour_start: 1
          hour_end: 21
          interval_count: 7
          cron_dmw: "*/15 * *"
```

### Inputs

| name   | value | default | description |
|--------| ----- | ------- |-------------|
| workflow_name | string | `${{ github.workflow_ref }}` | The modified workflow file name path <br /> defaults to the current workflow path <br /> e.g. `.github/workflow/cron.yml` |
| push_switch | boolean | true | The modified workflow_file push or not at once |
| github_token | string  | `${{ github.token }}` | The GitHub PAT key with at least `repo` and `workflow` permissions<br /> [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token). |
| repository | string | `${{ github.repository }}` | Repository name. <br /> The default is the current github repository <br /> If you want to push to other repository, <br /> you should make a [personal access token](https://github.com/settings/tokens) <br /> and use it as the `github_token` input. |
| ref_branch | string | `${{ github.ref_name }}` | The modified workflow_file push to destination branch |
| keep_history | boolean | false | Keep except workflow_file history commit message outside of the file |
| author | string | `github-actions[bot] <github-actions[bot]@users.noreply.github.com>` | Author name and email address as `Display Name <joe@foo.bar>` (defaults to the GitHub Actions bot user) |
| time_zone | string | `UTC+0` | The time zone of the user's region, with a range of `UTC±12`, automatically rounded down e.g. UTC+3.5 => UTC+3 |
| hour_start | number | 0 | Define the intervals start hour |
| hour_end | number | 23 | Define the intervals end hour |
| interval_count | number | 2 | Number of intervals to divide the day into, the number of runs per day |
| cron_dmw | string | `"* * *"` | Custom `Cron` DayofMonth Month DayofWeek |

## Troubleshooting

```log
 ! [remote rejected] dev -> dev (refusing to allow a GitHub App to create or update workflow `.github/workflows/xxxx.yml` without `workflows` permission)
error: failed to push some refs to 'https://github.com/xxx/xxxx.git'
Error: Process completed with exit code 1.
```

Due to the involvement of modifying and pushing workflow files, the default `GITHUB_TOKEN` doesn't have corresponding permissions. Please be sure to `settings` -> `Secrets and variables` -> `New repository secret` add a personal private key  
```
name: PAT
secret: ghp_XXXXXXXXXX
```
If not, the creation method is as follows:

- Click on the icon on the right[![PAT](https://github.githubassets.com/favicons/favicon.png)](https://github.com/settings/tokens/new) ，Set token key
- Fill in a name in the `Note` section -> Select an expiration date at `Expiration` -> Check the `Select scopes` in order`repo`、`workflow`、`write:packages`和`delete:packages` -> Click on the bottom `Generate token`

![Personal Access Token](https://github.com/grbnb/random-workflow-cron/blob/img/img/PAT.png)

```log
remote: Permission to xxx/xxxxx.git denied to github-actions[bot].
fatal: unable to access 'https://github.com/xxx/xxxxx.git/': The requested URL returned error: 403
Error: Invalid exit code: 128
```

Add GitHub API `token` key to your workflow yml file at `uses: actions/checkout@v3` in step
```yml
- name: Checkout
  uses: actions/checkout@v4
  with:
    token: ${{ secrets.PAT }}
    fetch-depth: 2
```

Then add the generated PAT key to the repository's `Actions secrets and variables`

## License

The Dockerfile and associated scripts and documentation in this project are released under the [MIT License](LICENSE).

## No affiliation with GitHub Inc.

GitHub are registered trademarks of GitHub, Inc. GitHub name used in this project are for identification purposes only. The project is not associated in any way with GitHub Inc. and is not an official solution of GitHub Inc. It was made available in order to facilitate the use of the site GitHub.