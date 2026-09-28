# STAT6011：R Markdown 环境与使用

环境已经安装在本课程目录的 `.tools` 中：R 4.6.1、Pandoc 3.11、TinyTeX，以及 `rmarkdown`、`knitr`、`statmod`、`glmnet`、`languageserver` 等 R 包。VS Code 已安装 REditorSupport.r 扩展。课程的 `.vscode/settings.json` 指向这份 R，`.vscode/tasks.json` 提供渲染任务。

这是 **Rmd → R/knitr → Pandoc → PDF 或 HTML** 的完整环境；所有作业计算都由 R 执行。可参考 [R Markdown 官方说明](https://rmarkdown.rstudio.com/docs/) 与 [官方入门](https://rmarkdown.rstudio.com/lesson-1.html)。

## 最方便的用法

1. VS Code 使用“打开文件夹”，打开 `E:\CS\hku_course\STAT6011`，不要只打开单独一个 Rmd。
2. 编辑 `hw1/STAT6011_HW1.Rmd`。先把开头 `author` 改成自己的姓名与学号。
3. 按 **Ctrl+Shift+B**，执行默认任务 **HW1: Render PDF and HTML**。
4. 打开 `hw1/STAT6011_HW1.pdf` 检查提交版。双击 `STAT6011_HW1.html` 可在浏览器阅读。
5. 中文讲解在 `hw1/HW1学习讲解.md`，VS Code 按 **Ctrl+Shift+V** 可预览 Markdown。

如 Windows 弹出 workspace trust，只有确认打开的是你自己的课程文件夹后再选择信任。若 R 扩展刚装好但语言服务尚未加载，可重载 VS Code 窗口。

## PowerShell 一条命令重新生成

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "E:\CS\hku_course\STAT6011\Render-HW1.ps1"
```

只生成 HTML：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "E:\CS\hku_course\STAT6011\Render-HW1.ps1" -Format html
```

这里的 ExecutionPolicy 参数仅对该次 PowerShell 进程生效，不修改电脑的全局策略。脚本会设置本次渲染所需的 Pandoc/LaTeX 路径，然后在 `hw1` 目录启动 R。

## 在 VS Code 中逐行学习

命令面板运行 `R: Create R terminal`；选中 R 代码后按 **Ctrl+Enter** 送到终端。首次手动学习时先执行：

```r
setwd("E:/CS/hku_course/STAT6011/hw1")
```

按顺序运行 setup 和前面的代码块。手动交互终端与一键渲染是不同的 R 会话，所以不要依赖终端里已有变量来保证作业能渲染。一键渲染会重新执行完整文档，这也是提交前应该再做一次的检查。

这份作业不需要 RStudio；以后若使用 RStudio，也可以打开相同 Rmd，但需让其找到这里安装的 R 和 TinyTeX。不要直接复制 tutorial 中老师的 Mac `setwd` 路径。

## 文件用途与提交

| 文件 | 用途 |
|---|---|
| `hw1/STAT6011_HW1.Rmd` | 可修改的作业源文件 |
| `hw1/STAT6011_HW1.pdf` | knit 后的提交稿 |
| `hw1/STAT6011_HW1.html` | 便于浏览器阅读的版本 |
| `hw1/HW1学习讲解.md` | 中文学习解释、研究联系和讲义定位 |
| `hw1/Q3.csv`、`hw1/Q4.csv` | 原始数据，保持不变 |
| `Render-HW1.ps1`、`render_hw1.R` | 本机一键渲染入口 |
| `.tools/`、`.vscode/` | 运行环境与编辑器配置，不是作业内容 |
| `tmp/` | 安装日志、独立数值核查与 PDF 排版检查，不用提交 |

作业 PDF 要求计算使用 R；tutorial 进一步要求 **Rmd 与 PDF 一起提交**，不是只上传 Rmd。没有替你向 Moodle 提交任何文件。

## 当前需要你留意的两点

- 姓名学号仍为占位文字，提交前需要填写并重新渲染。
- Q3 的题设 prior-proposal rejection sampling 接受率极低；原算法各一百万次没有接受点。成品保留这个事实，并用明确标注的替代 proposal 生成同一 posterior 的 1000 个独立样本。它在后验目标上正确，但算法限定需要向老师核实。不能直接把补充样本称为原算法结果。

作答用固定 seed，重复渲染可复现。图与表均由 R 实际生成。HTML 的数学公式通常需要联网加载 MathJax；离线阅读以 PDF 为准。以后如果移动整个课程目录，需更新 `.vscode/settings.json` 的 R 路径；渲染脚本按自身位置寻找工具。
