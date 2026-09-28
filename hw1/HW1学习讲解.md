# HW1 学习讲解：从计算方法走到贝叶斯思维

这份文档配合 `hw1/STAT6011_HW1.Rmd` 阅读。作业正文用英文，保留代码、必要推导和结果；这里解释为什么这样做，以及哪些地方容易误解。所有作业模拟、数值积分、优化和回归计算都在 R 中完成。

建议顺序：先读这里的第 1、2、4 题，再读第 3 题。第 3 题的原始采样要求在这份数据上几乎不可计算，先理解其余题目，再处理这个困难会轻松一些。

**当前作业是一份供你理解和修改的完整草稿。** 姓名学号尚未填写；第 3 题保留了指定算法和真实失败记录，但图表使用了明确标注的替代 proposal。它生成的是同一个后验的独立样本，却不满足“必须以 prior 为 proposal”这一算法限定。提交前应确认老师是否接受这个处理；不能把它描述成原算法成功抽到了 1000 个样本。

## 1. 先建立这次作业的地图

| 题目 | 在做什么 | 对应课程材料（PDF 页码） |
|---|---|---|
| Q1 | 随机变量变换与模拟检验 | tutorial 1 的分布函数、密度图、Gamma to Beta 部分 |
| Q2 | 把积分写成期望，再选择采样分布降低方差 | lecture1 第 26–29、50–55 页；lecture2GaussianQuadrature 第 2、6–9 页；MLE vs MAP Rejection Importance 第 22–26 页 |
| Q3 | 后验采样、接受率、先验与正则化 | lecture1 第 36–49 页；tutorial 1 Rejection Sampling；Bayesian Lasso 第 7–15 页 |
| Q4 | 正态共轭更新与固定点迭代 | lecture1 第 8 页起的 Normal Example；MLE vs MAP Rejection Importance 第 10 页 |

文件链接：[lecture1](../lecture1.pdf)、[Gaussian quadrature](../lecture2GaussianQuadrature.pdf)、[Bayesian Lasso](<../Bayesian Lasso 2026.pdf>)、[MLE/MAP 与采样](<../MLE vs MAP Rejection Importance-2026.pdf>)、[tutorial 源文件](../t1/t1/t1.Rmd)。

其他讲义也已检查，但不需要把所有内容塞进 HW1。`lecture3bootstrap` 和 `Bootstrap vs Bayesian Bootstrap` 可用于以后区分“重采样数据”和“抽样后验参数”；`lecture4LindleyBF` 适合继续学习检验与模型比较；`Gaussian quadrature using Hermite polynomials` 将局部高斯近似联系到积分；`Numerical Differentiation` 与优化有关。这次第 2 题用 Legendre，不能因为讲义介绍了 Hermite 就直接套 Hermite。

## 2. Rmd 怎么读、怎么改

一个 Rmd 文件同时放三种东西：普通说明文字、LaTeX 数学公式、R 代码块。比如：

````markdown
The posterior variance is $1/(n+1/4)$.

```{r example}
n <- 100
1/(n + 1/4)
```
````

Knit/render 会执行代码，再把代码、结果和文字排成文档。我们没有手动把计算结果粘进正文；不少结论通过 inline R（如 `` `r round(mc, 4)` ``）自动更新，修改数据或 seed 后不会忘记同步数字。

- `echo=TRUE`：显示代码，符合本次作业需要。
- `include=FALSE`：代码照常执行，但不显示该块及其输出；适合 setup。
- `set.seed(...)`：让随机结果可复现，不是挑出“好看”的结果。
- `rnorm` 的 `sd` 是标准差，题目给 $N(0,5^2)$ 时写 `sd=5`。
- `read.csv(..., row.names=1)`：把 CSV 第一列作为行号，避免误当预测变量。
- `model.matrix(fit)`：自动生成截距列与十个自变量组成的设计矩阵。

不要照搬 tutorial 里的 Mac 绝对路径，也不要在每个 chunk 中运行 `rm(list=ls())`。同一个 Rmd 的后续块会用到前面的变量。我们的数据与 Rmd 放在同一个 `hw1` 文件夹，渲染时自然能找到 `Q3.csv` 和 `Q4.csv`。

详细使用方式见 [环境与操作说明](../RMD使用说明.md)。

## 3. Q1：模拟现象、统计检验和数学结论是三件事

题目从标准正态生成 $X$，再取 $Y=X^2$。这不是对数据做任意加工：卡方分布的定义就是若干独立标准正态的平方和，自由度为 1 时只有一个平方。

对于 $t\geq0$：

$$
P(Y\leq t)=P(-\sqrt t\leq X\leq\sqrt t)
=2\Phi(\sqrt t)-1.
$$

对 $t$ 求导得到 $\chi^2_1$ 密度。这个关系是精确的；直方图是有限次模拟的近似。靠近零点时密度趋于无穷，但一个有限宽度柱子的高度是区间内平均密度，所以两者在零附近看起来不重合是正常的。

作答用 `ks.test(y, "pchisq", df=1)`，比较经验 CDF 和理论 CDF。这里没有从数据估计未知参数，因此使用这个完全指定分布的单样本 KS 检验是合适的。本次 p 值约为 **0.8809**，没有拒绝原假设。

这不表示“原假设有 88% 的概率为真”。p 值是在原假设成立时，得到当前或更极端检验统计量的概率。即使生成机制确实正确，也存在小概率拒绝的随机运行；不应该不断改 seed 直到检验通过。

对研究的联系：做 simulator 或 policy evaluation 的 sanity check 时，分清“理论上应该满足”“有限样本图像接近”“统计检验未发现差异”。一次不显著的检验不足以证明实现完全正确，但已知分布的模拟测试能帮助发现明显错误。

## 4. Q2：Monte Carlo 的关键是在哪个分布下取平均

### 4.1 Uniform 方法为何成立

这里 $I=\int_0^1 h(x)\,dx$，而 $U\sim\operatorname{Unif}(0,1)$ 的密度是 1，因此 $I=E[h(U)]$。直接把期望换成平均值：

$$
\widehat I=\frac1n\sum_{i=1}^n h(U_i).
$$

它的 Monte Carlo standard error（MCSE）估计为 `sd(h(u))/sqrt(n)`。这描述模拟本身的误差；不是原始数据的观测噪声，也不是贝叶斯后验标准差。

样本数增加 100 倍，MCSE 通常只减少 10 倍。这也是值得研究更好 proposal 的原因。

### 4.2 Beta 采样后为什么必须除以密度

如果改从 $f(x)$ 抽样，出现频率已经发生变化。为了仍然计算原来的积分，必须补偿：

$$
I=E_f\left[\frac{h(U)}{f(U)}\right].
$$

因此代码是 `mean(h(u.beta)/dbeta(u.beta, alpha, beta))`，不能只用 `mean(h(u.beta))`。这题是普通 importance sampling，不需要再把权重归一化；后者通常用于目标归一化常数未知时，有限样本下也有不同的偏差性质。

### 4.3 “最准确的参数”应该怎样定义

不能试很多参数、各随机跑一次，再挑恰好最接近 benchmark 的结果。这会把随机好运误当作方法改进。作业已经提示 highest efficiency，应理解为固定样本数下最小方差：

$$
\operatorname{Var}(\widehat I)=\frac1n\left[
\int_0^1\frac{h(x)^2}{f_{\alpha,\beta}(x)}dx-I^2\right].
$$

$I$ 不随参数变化，所以只优化积分项。注意这里是 **$h^2/f$**，而 $h$ 本身已经是一个平方。

R 中 `integrate` 计算这个二阶矩，`optim` 调整两个 Beta 参数。端点附近，$f(x)$ 分别像 $x^{\alpha-1}$ 和 $(1-x)^{\beta-1}$；本题的 $h$ 在两个端点均不为零。因此二阶矩有限需要 $\alpha<2,\beta<2$，同时 Beta 分布要求两者大于零。极靠近 2 时积分数值上也较难处理，不适合随意把上界设得很大。

结果约为 **$\alpha=1.0780,\beta=1.0145$**，与均匀分布的 $(1,1)$ 很近。方差仅降低 **0.69%**。这很合理：$h(x)$ 有许多振荡峰谷，单个 Beta 密度没有足够的形状自由度去匹配它们。

不限制 proposal 家族时，非负 $h$ 的最优密度为 $f^*(x)=h(x)/I$，因为此时 $h(U)/f^*(U)=I$ 是常数，方差为零。这主要是一个理解最优 proposal 的参照：其归一化常数正是待求的积分，通常不能直接拿来解决问题。

### 4.4 为什么 quadrature 用 Legendre

Gaussian quadrature 中的 Gaussian 不是说必须从正态分布抽样，而是通过节点与权重获得高阶精确性的一类求积规则。

把 $x\in[0,1]$ 映射成 $t\in[-1,1]$：

$$
x=(t+1)/2,\qquad dx=dt/2,
\quad I\approx\frac12\sum_k w_kh((t_k+1)/2).
$$

有限区间、权重为 1，正好适合 Gauss–Legendre。Gauss–Hermite 对应无限区间和指数平方权重，不能直接套在这里。我们比较 64 与 128 个节点，结果稳定在 **0.9652** 附近。这才是 (c) 的 Gaussian quadrature benchmark；(b) 中用 `integrate` 做优化，不是把它冒充成 (c) 的实现。

### 4.5 和强化学习的联系

Off-policy evaluation 也在做分布转换：用 behavior policy 的数据估计 target policy 下的期望，权重中出现两种分布的比值。Q2 是这个结构的一维简化例子。

应该关注的不只是“权重公式写对没有”，还有 proposal 是否覆盖重要区域、权重的二阶矩是否足够小。分布重叠差时，即使估计量无偏，有限数据表现也可能很差。RL 中常用的 clipping 可以降低权重的极端程度，但会改变偏差与方差，不能当成免费改进。这些是结构上的联系，不意味着本题的最优 Beta 参数能直接迁移到策略学习。

## 5. Q3：先验、后验与 proposal 不要混在一起

### 5.1 模型与 MLE

模型是 $y=X\beta+\epsilon$，$\epsilon\sim N(0,vI)$，$v=\sigma^2$。数据有 100 行、10 个特征，加上截距后有 11 个系数。

题目先写 $\beta_0,\ldots,\beta_{10}$，又把先验下标写成 $j=1,\ldots,11$，应理解为这 11 个系数都具有相同先验，而不是漏掉截距或多出一个系数。

$$
\widehat\beta=(X^TX)^{-1}X^Ty,\qquad
\widehat v=\frac{\|y-X\widehat\beta\|^2}{n}.
$$

这里 $\widehat v\approx0.8004$。`summary(lm(...))` 给的残差标准差涉及 $n-p$ 自由度校正，不能直接平方后叫作 variance MLE。

我们的 inverse-gamma 定义为 $p(v)\propto v^{-a-1}e^{-b/v}$，所以 `1/rgamma(..., shape=a, rate=b)` 正确。R 的 Gamma `rate` 和 `scale` 互为倒数，不能混用。

### 5.2 原始 rejection sampler 为何几乎不接受

目标后验是 $p(\theta\mid y)\propto L(\theta)\pi(\theta)$。从 prior 采样后，用 $L(\theta)/L_{\max}$ 接受，留下的点就服从 posterior。

数学上这很漂亮；计算上却要求 prior 抽到 likelihood 足够大的狭窄区域。11 个系数都要大致合适，方差也要合适，联合概率会非常小。

程序对两种 prior 各做了 100 万次尝试，均未接受任何点。这一事实只能说明本次没有接受，不能据此断言两种接受率都严格为零，更不能比较“谁是零得更少”。补充积分估算得到：

| 原始 proposal | 估计接受率 | 获得 1000 个接受点的期望提议数 |
|---|---:|---:|
| Normal prior | $5.07\times10^{-19}$ | $1.97\times10^{21}$ |
| Laplace prior | $2.86\times10^{-12}$ | $3.50\times10^{14}$ |

因此题目问哪种 prior 更有效率，答案是这里的 **Laplace prior**，但两者都不适合直接跑到 1000 个样本。Normal 的接受率另用解析积分掉 $\beta$ 后的一维数值积分核对，得到约 $5.0736\times10^{-19}$，与上面的估计相符。

接受概率用 log 计算是为了避免浮点数下溢：`log(runif(m)) <= log.a`。它解决数值表示问题，不会改变真实接受率。把最大的已观测 likelihood 当成真正上界、擅自降低 envelope、或只保留“最好”的 1000 个点，都会改变目标分布，不能这样补结果。

### 5.3 补充算法改了什么，没改什么

这里稍微超出普通作答，是因为原算法确实跑不出所需样本。第一次可以只读结论，再回看推导。

记 $A=X^TX$，$S=\|y-X\widehat\beta\|^2$，则

$$
\|y-X\beta\|^2=S+(\beta-\widehat\beta)^TA(\beta-\widehat\beta).
$$

先构造 $q(\beta,v)\propto L(\beta,v)\pi(v)$，暂不放系数先验。积分掉 $\beta$ 带来 $v^{p/2}$，于是

$$
v\sim IG\left(0.1+\frac{n-p}{2},0.1+\frac S2\right),\qquad
\beta\mid v\sim N(\widehat\beta,vA^{-1}).
$$

再按 $\pi(\beta)/\pi(0)$ 接受，目标就恢复为 $L\pi(v)\pi(\beta)$。Normal 情况接受概率是 $e^{-\sum\beta_j^2/50}$；Laplace 情况是 $e^{-\sum|\beta_j|}$。

所以这不是把系数先验换成 flat prior 来交作业；flat 部分只用于构造 proposal，接受步骤把题设先验补回来了。也不是近似正态后验或 MCMC：它仍然是精确的独立 rejection sampling（除通常的浮点与随机模拟误差）。不过，它**确实换了 proposal**，这一点不能隐去。

这次补充算法得到 1000 个 Normal 后验点用了 1093 次提议，Laplace 用了 109005 次。这个次序与原先验 proposal 相反，说明“哪个 prior 的采样快”离不开 proposal 的具体选择。

接受率估算利用 $p(y)=Z_0\pi(0)E_q[\pi(\beta)/\pi(0)]$，再除以 $L_{\max}$。这部分是解决计算困难的补充，不是本次课程最需要死记的公式。

### 5.4 后验图表如何读

红色虚线是 MLE；灰色柱子和蓝色密度曲线描述 posterior。表格的 posterior variance 是参数的不确定性，不是 posterior mean 的 MCSE。1000 个独立样本算均值时，MCSE 约等于 posterior SD 除以 $\sqrt{1000}$。

Normal prior 的均值多数接近 MLE；Laplace 对一些弱识别的系数产生更明显收缩。例如截距后验均值约从 1.154 变为 0.775，$\beta_8$ 约从 −0.420 变为 −0.128。

不要要求每一个系数都必须绝对值减小。相关特征会重新分担解释作用，某个系数可能变大。数据也没有提供 true beta 列，所以不能声称已经识别出全部真实零系数。

### 5.5 Ridge/Lasso 对应 MAP，不直接对应 posterior mean

固定 $v$ 后，负 log posterior 去掉常数分别是

$$
\frac{\mathrm{RSS}(\beta)}{2v}+\frac{\|\beta\|_2^2}{50},
\qquad
\frac{\mathrm{RSS}(\beta)}{2v}+\|\beta\|_1.
$$

最小化它们得到条件 MAP，也就是相应惩罚强度的 ridge/Lasso 解。作业先固定 $v=\widehat v$ 做这个比较；它不是同时对 $v$ 求联合 MAP，也不是积分掉 $v$ 后的边际 MAP。

Lasso 在零点有尖角，会通过 soft thresholding 把一部分 mode 坐标压到精确的零。连续 Laplace prior 下，某个系数恰好等于零的 posterior probability 仍是零；posterior draws 和 posterior mean 通常也不精确为零。若想要“系数等于零的后验概率”，需要带点质量的模型，例如 spike-and-slab，而不是把 Lasso 的零当作这个概率。

本次匹配 prior 的比较把截距也惩罚，并保持原始变量尺度。Lasso 用简短 coordinate descent，因为普通 `glmnet` 会去掉常数预测列，不能靠把全 1 列当作特征来实现这个惩罚截距的要求。软阈值更新来自逐坐标的一维优化。

另外的 CV ridge/Lasso 是通常的预测建模：标准化特征、截距不惩罚、10-fold CV 选择 lambda。因此它们不是题设 prior 下的完全相同模型。两种比较都保留，是为了分别回答“先验对应什么 penalty”和“常规正则化回归会怎么拟合”。

### 5.6 和具身智能研究的联系

你可以把 $\beta$ 类比成 dynamics model 的未知参数。只训练一个正则化最优模型，相当于保留一个点估计；posterior 还描述哪些参数方向被数据约束得很弱。

做预测时，参数不确定性应通过

$$
p(y_*\mid D)=\int p(y_*\mid\theta)p(\theta\mid D)d\theta
$$

传播出去。在线性高斯模型里可以具体分解预测方差；在一般非线性模型中，直接把 posterior mean 参数代入，通常不等于对预测分布做积分。

从这个角度看，探索需要的 uncertainty 不只是训练残差大小。观测噪声与知识不足是不同来源；不确定的模型参数会影响规划，而模拟点数增加只减少 Monte Carlo 误差，不会凭空提供真实环境信息。

另一个实用提醒：给所有系数相同 prior scale，实际假定了变量单位。米和毫米会改变数值尺度以及同一个 L1/L2 penalty 的含义。研究中讨论 regularization 时，要同时说清参数化与特征缩放。

## 6. Q4：共轭更新变成一个有噪声的固定点迭代

### 6.1 精度加权的 posterior

先写一般 prior $\mu\sim N(m,4)$。观测方差为 1，$n$ 个观测的 likelihood precision 是 $n$，prior precision 是 $1/4$：

$$
v_{post}=\frac1{n+1/4},\qquad
m_{post}=\frac{n\bar y+m/4}{n+1/4}.
$$

这是一个 precision-weighted average。数据越多，prior mean 的影响越小。原始 prior 取 $m=0$；本题 $\bar y=0.842$，初始 posterior mean 约为 **0.8399002**，posterior variance 约为 **0.0099751**。

### 6.2 PPMM 为什么靠近 MLE

如果直接使用精确 posterior mean 更新 prior mean，

$$
m_{j+1}-\bar y=\frac{m_j-\bar y}{4n+1}.
$$

固定点是 $\bar y$。本题 $n=100$，误差每次乘以 $1/401$，所以很快接近固定点。Normal log likelihood 严格凹，因此这里驻点就是唯一 MLE；一般模型不能仅凭一阶导数等于零就断言找到了全局最大值。

题目要求每轮抽 1000 个 posterior samples 再求均值，所以实际还有随机误差：

$$
\widehat m_{j+1}=m_{post}(m_j)+\epsilon_j,
\qquad \operatorname{SD}(\epsilon_j)\approx0.0031583.
$$

固定每轮样本数时，迭代会在固定点附近晃动，并不严格收敛到一个实数。这和 noisy optimization 中步间变化受到抽样噪声支配的情形相似。

代码以连续三轮变化小于 $3\times MCSE$ 作为实用停止条件，并保留 100 次迭代上限。本次在第 4 轮停止，结果约 **0.83619**，与 MLE 差 **−0.00581**，约为单轮 1.84 个 MCSE。不能把这个差异全部解释成算法的系统偏差。

### 6.3 为什么不能叫作“又看到了 100 个新数据”

这里每轮使用的是同一份数据，只把 prior mean 移到当前 posterior mean，prior variance 仍然固定为 4。它是题目设计的优化过程，不是标准的 sequential Bayes。

真正的新数据更新应传递完整 posterior，并使用尚未纳入的数据 likelihood。如果一边重复使用旧数据，一边又把上一轮 posterior 当新 prior，相当于把同一份证据重复计数，可能产生虚假的自信。

对 RL/机器人，这个区别在重复利用 replay data、在线系统辨识以及不确定性传播中很有价值。重复优化数据集可以合理，但“优化步骤变多”和“统计证据变多”不是同一回事。

## 7. 你可以怎样把这份作业变成自己的理解

第一遍不必记住全部公式，先能用自己的话回答：

1. Q1 的 p 值为何不是模型正确的概率？
2. Q2 改用 Beta 抽样后，漏掉 density ratio 会估计什么？为什么最优参数接近 uniform？
3. Q3 同一个 posterior 为什么可以有完全不同的采样效率？Lasso 的零与 posterior probability of zero 有什么区别？
4. Q4 若把每轮 1000 个样本改成 100 个，停止阈值应该怎样随之变化？固定点是否改变？

然后做两个小改动就足够：换一个 seed，观察 Q2 单次误差和 Q4 末轮结果如何变化；再比较 Q3 的 posterior mean、matched MAP 和 CV Lasso，挑一个系数写三句话解释它们为何不同。不要为了结果“更漂亮”去筛选 seed。

提交前填写姓名学号，读懂并决定如何处理 Q3 的方法限制。tutorial 明确要求上传 Rmd 与 PDF；中文讲解、HTML 和环境文件留作自己学习即可。
