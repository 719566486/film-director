# AI 短片导演手册 · film-director

把一个创作意图写成可拍、可剪的镜头。适用于真人风格、动画和可灵图生视频，也可用来诊断已有样片。内含 30 部 AI 影像制作案例、24 位中外导演的方法、原创机位图和一场 28 秒的完整分镜。

## 调用

用 Codex CLI 或 IDE 打开此仓库，输入 `/skills` 后选择 `film-director`，也可输入 `$film-director`。用 Claude Code 打开此仓库，输入 `/film-director` 并接上任务。各客户端使用自己的技能发现机制。ChatGPT 中的账户技能另行管理。

```text
/film-director 20 秒，父亲把老照相馆交给女儿。先让观众以为要关店，
最后才明白是交班。写六个镜头、台词语气、声音剪点和可灵动作描述。
```

把示例开头换为 `$film-director` 即为 Codex 调用形式。已有分镜可只指定要修的镜号，例如“第 3 镜只有推近，帮我安排一个能改变两人关系的动作”。

## 安装到其他项目

仓库内已提供两个项目级入口。要让同一台机器上的其他项目也能使用，在仓库根目录运行：

```sh
python install.py --client both
```

也可只选 `--client codex` 或 `--client claude`。安装器仅使用 Python 标准库，将完整技能写入用户目录下对应客户端的 skills 文件夹。重复安装相同内容时跳过；遇到不同版本时保留已有文件并报告路径。为已打开的客户端新建会话以重新发现技能。

## 可阅读的内容

- [导演工作指令](.agents/skills/film-director/SKILL.md)
- [24 位导演的方法、来源与原创场景推演](.agents/skills/film-director/references/directors.md)
- [30 部 AI 影片案例与资料链接](.agents/skills/film-director/references/ai-films.md)
- [从景别、动作、声音到可灵分镜的工作页](.agents/skills/film-director/references/workbook.md)

研究条目注明资料依据；迁移示例为原创。生成片段需使用所在客户端已接入且获授权的视频服务。本项目本身没有 API 密钥、联网脚本或付费调用。

项目原创文字、示意图和代码采用 [MIT 许可证](LICENSE)。外链影片与文献的权利属于各自权利人。

[Codex 技能说明](https://developers.openai.com/codex/skills/) · [Claude Code 技能说明](https://code.claude.com/docs/en/skills)

