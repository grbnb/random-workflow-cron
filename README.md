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
    permissions:
      contents: write
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Random Cron
        uses: grbnb/random-workflow-cron@v1
        with:
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
    permissions:
      contents: write
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          repository: ${{ github.repository }}
          ref: dev
      
      - name: Random Cron
        uses: grbnb/random-workflow-cron@v1
        with:
          workflow_name: ".github/workflows/ci.yml"
          ref_branch: dev
          keep_history: true
```

Set the random hour range to `1-21` [UTC+0 time zone], running only 5 times a day every 15 days, but not immediately pushing and commit to the repository. This means that there are push operations in the steps after the workflow file, avoiding multiple push operations!!!

```yml
name: 'random-cron'

on:
  schedule:
    - cron: '0 0 */17 * *'
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Random Cron
        uses: grbnb/random-workflow-cron@v1
        with:
          push_switch: false
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
| github_token | string  |  `${{ github.token }}` | [GITHUB_TOKEN](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#using-the-github_token-in-a-workflow) <br /> or a repo scoped <br /> [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token). |
| repository | string | `${{ github.repository }}` | Repository name. <br /> The default is the current github repository <br /> If you want to push to other repository, <br /> you should make a [personal access token](https://github.com/settings/tokens) <br /> and use it as the `github_token` input. |
| ref_branch | string | `${{ github.ref_name }}` | The modified workflow_file push to destination branch |
| keep_history | boolean | false | Keep except workflow_file history commit message outside of the file |
| author | string | `github-actions[bot] <github-actions[bot]@users.noreply.github.com>` | Author name and email address as `Display Name <joe@foo.bar>` (defaults to the GitHub Actions bot user) |
| hour_start | number | 0 | Define the intervals start hour |
| hour_end | number | 23 | Define the intervals end hour |
| interval_count | number | 2 | Number of intervals to divide the day into, the number of runs per day |
| cron_dmw | string | `"* * *"` | Custom `Cron` DayofMonth Month DayofWeek |


## Troubleshooting

- Question
```log
remote: Permission to xxx/xxxxx.git denied to github-actions[bot].
fatal: unable to access 'https://github.com/xxx/xxxxx.git/': The requested URL returned error: 403
Error: Invalid exit code: 128
```
method (1):  
Add the following code to your workflow yml file
```yml
permissions:
  contents: write
```
method (2): [recommended]  
Please set the `Workflow permissions` of this repository to `Read and write permissions`, the specific steps are:  
`settings` -> `actions` -> `General` -> `Workflow permissions` -> `Read and write permissions`  

method (3):  
Add GitHub API `token` key to your workflow yml file at `uses: actions/checkout@v3` in step
```yml
- name: Checkout
  uses: actions/checkout@v3
    token: ${{ secrets.PAT }}
```
Then add the generated PAT key to the repository's `Actions secrets and variables`

## License

The Dockerfile and associated scripts and documentation in this project are released under the [MIT License](LICENSE).

## No affiliation with GitHub Inc.

GitHub are registered trademarks of GitHub, Inc. GitHub name used in this project are for identification purposes only. The project is not associated in any way with GitHub Inc. and is not an official solution of GitHub Inc. It was made available in order to facilitate the use of the site GitHub.