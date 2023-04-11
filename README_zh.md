# GitHub Action for workflow cron

[README](README.md) | [中文文档](README_zh.md)

用于使用 GitHub 令牌授权推送到 GitHub 存储库更改工作流cron的 GitHub 操作。

使用场景:

- 用于GitHub actions工作流无规律调度运行
- 自动生成随机cron表达式, 只针对`hour`和`minute`随机生成

## 用法

### 示例工作流文件

将当前分支工作流文件中的`schedule`下的`cron`表达式进行随机修改(自己修改自己)，并且保留除工作流文件外的文件历史提交描述：

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

将当前仓库中的其它分支`dev`工作流文件`ci.yml`中的`schedule`下的`cron`进行随机修改(修改其它文件)[不建议]，并且保留除工作流文件外的文件历史提交描述：

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

设置随机小时范围为`1-21`[UTC+0时区]，每间隔15天并且一天只运行5次， 但是不立即推送提交到仓库，即工作流文件后面的步骤存在推送操作，避免多次推送！！！

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

### 自定义变量

| 变量名   | 变量值类型 | 默认值 | 描述 |
|--------| ----- | ------- |-------------|
| workflow_name | string | `${{ github.workflow_ref }}` | 修改的工作流文件名路径 <br /> 默认为当前工作流路径  <br /> 例如：`.github/workflow/cron.yml` |
| push_switch | boolean | true | 修改后的工作流文件是否立即推送 |
| github_token | string  |  `${{ github.token }}` | [GITHUB_TOKEN](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#using-the-github_token-in-a-workflow) <br /> or a repo scoped <br /> [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token). |
| repository | string | `${{ github.repository }}` | 存储库名称. <br /> 默认为当前github存储库 <br /> 如果您想推送到其他存储库, <br /> 你应该创建一个[personal access token](https://github.com/settings/tokens) <br /> 并将其用作`github_token`输入 |
| ref_branch | string | `${{ github.ref_name }}` | 修改后的工作流文件推送的目标分支 |
| keep_history | boolean | false | 保留除`workflow_file`文件外的历史记录提交描述 |
| author | string | `github-actions[bot] <github-actions[bot]@users.noreply.github.com>` | 作者姓名和电子邮件地址作为`显示名称 <joe@foo.bar>`(默认为`GitHub Actions`机器人程序用户) |
| hour_start | number | 0 | 定义区间开始时间 |
| hour_end | number | 23 | 定义区间结束时间 |
| interval_count | number | 2 | 将一天划分的间隔数,即一天运行的次数 |
| cron_dmw | string | `"* * *"` | 自定义 `Cron` 日期 月份 星期 |


## 遇到问题

```log
remote: Permission to xxx/xxxxx.git denied to github-actions[bot].
fatal: unable to access 'https://github.com/xxx/xxxxx.git/': The requested URL returned error: 403
Error: Invalid exit code: 128
```
方法 (1):  
将以下代码添加到工作流yml文件中
```yml
permissions:
  contents: write
```
方法 (2): [推荐]  
请将此存储库的`Workflow permissions`设置为`Read and write permissions`，具体步骤为：
`settings` -> `actions` -> `General` -> `Workflow permissions` -> `Read and write permissions`  

方法三 (3):  
添加GitHub API `token`密钥到工作流yml文件的`uses:actions/checkout@v3`步骤中
```yml
- name: Checkout
  uses: actions/checkout@v3
    token: ${{ secrets.PAT }}
```
然后将生成的PAT密钥添加到存储库的`Actions secrets and variables`中

## 许可证

本项目中的Dockerfile及相关脚本和文档是根据[MIT许可证](LICENSE)发布的。

## 与GitHub股份有限公司无关联

GitHub是GitHub，Inc.的注册商标。本项目中使用的GitHup名称仅用于识别目的。该项目与GitHub股份有限公司没有任何关联，也不是GitHup股份有限公司的官方解决方案。提供该项目是为了方便使用GitHub网站。
