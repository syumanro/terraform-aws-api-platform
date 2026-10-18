# 中文学习入口

[日本語版](learning-guide.ja.md)

当前 Terraform 文件使用 HashiCorp 推荐的简单 `#` 注释，以简短英文标识功能分组，不使用装饰性分隔线或逐行讲解。详细学习说明保留在本目录的文档中。空行只用于分组，不参与执行。Docker、构建、部署、任务模板和本地预览脚本的每一行在 [构建部署逐行说明](deployment-line-by-line.md) 中讲解；JSON 不允许直接加入注释，所以保持原模板可用。`app/` 的页面样式和图片属于演示内容，本次学习重点是基础设施与部署链路。

这些说明依据当前代码的行为编写。没有项目需求依据的值，例如日志保留天数、扩缩容阈值和等待时间，会说明影响与取舍，不会把推测写成作者已经确认的设计意图。本次只添加说明和调整格式，没有修改配置值，也没有执行部署。

## 建议阅读顺序

1. [根模块变量](../common/prd_test2/01_variables.tf)：理解如何将环境差异作为输入。
2. [Provider 与状态后端](../common/prd_test2/02_main.tf)：理解 Terraform 使用哪个 AWS 账号、区域以及在哪里记住资源状态。
3. [模块连接](../common/prd_test2/03_modules.tf)：先看全局依赖，再读每个模块。
4. [网络](../modules/network/main.tf) → [安全组](../modules/security_groups/main.tf) → [负载均衡](../modules/load_balancing/main.tf)：按一条请求的路径学习。
5. [ECS](../modules/ecs/main.tf)：理解集群、服务、任务定义和容器的关系。
6. [扩缩容](../modules/autoscaling/main.tf)：理解监控指标如何变成任务数量变化。
7. [ECR](../modules/ecr/main.tf) → [构建](../modules/cicd/codebuild.tf) → [流水线](../modules/cicd/codepipeline.tf) → [部署](../modules/cicd/codedeploy.tf)：理解新镜像如何替换运行版本。
8. [输出](../common/prd_test2/05_outputs.tf) 和 [构建部署逐行说明](deployment-line-by-line.md)：把资源地址、镜像地址和部署占位符串起来。

## 先认识几个语法

| 写法 | 含义 | 为什么这样组织 |
| --- | --- | --- |
| `resource "aws_subnet" "ecs_a"` | 声明一个资源；类型是 `aws_subnet`，内部名字是 `ecs_a` | 内部名字形成 Terraform 地址，与 AWS 的 Name 标签是两回事 |
| `variable "vpc_id"` | 声明调用者可以提供的输入 | 把环境参数与模块实现分开，便于复用 |
| `var.vpc_id` | 读取当前模块输入 | 子模块不会自动继承根模块所有变量，需要显式传入 |
| `aws_subnet.ecs_a.id` | 读取另一个资源创建后的 ID | Terraform 由引用判断依赖顺序，通常无需手写 `depends_on` |
| `module.network.ecs_subnet_ids` | 读取模块公开的 output | 让调用者只依赖公开接口，减少对内部资源名字的依赖 |
| `locals` / `local.xxx` | 定义并读取当前模块内部的计算值 | 复用表达式，不把实现细节暴露为外部参数 |
| `condition ? A : B` | 条件成立取 A，否则取 B | 这里通过证书是否为 null 选择 HTTP 或 HTTPS |
| `null` | 未提供值或省略可选配置 | 与空字符串、字符串 `"null"` 不同 |
| `{ ... }` / `[ ... ]` | 对象或配置块 / 列表 | 表达有层级的配置与多个元素；字符串列表要求元素加引号 |
| `jsonencode(...)` | 将 HCL 数据生成 JSON 字符串 | ECS 和 ECR 接口需要 JSON，这样可以避免手写转义与逗号 |
| `lifecycle.ignore_changes` | 更新时忽略指定字段的差异 | 允许其他系统管理这些字段，但也不能用 Terraform 修正这些字段的意外漂移 |

例如 `target_group_arn = module.load_balancing.production_target_group_arn`：左边是 ECS 模块的输入名，右边是负载均衡模块的输出。这样写既传递真实 ARN，又让 Terraform 知道要先得到目标组，再配置 ECS。输入名、输出名不必相同，含义和类型需要对应。

## 将配置放回实际流程中理解

用户请求的路径是 `Internet → 公网 ALB → 私有子网中的 ECS 任务（容器 80 端口）`。ALB 位于两个公有子网中，配置证书时终止 HTTPS；证书为空时使用 HTTP，端口号 443 不会自动提供加密。安全组限制来源与端口，路由表决定目的地址能否到达，两者需要同时满足。

发布路径是 `GitHub → CodePipeline Source → CodeBuild 构建和测试 → ECR 镜像 + S3 产物 → 人工审批 → CodeDeploy → 新 ECS 任务集`。GitHub 保存源码，ECR 保存镜像，S3 保存流水线文件，state 后端保存 Terraform 的资源状态，它们保存的东西不同。

`taskdef.json` 的 `<IMAGE1_NAME>` 由流水线镜像动作替换为 `imageDetail.json` 中的镜像 URI；注册新任务定义后，`appspec.yaml` 的 `<TASK_DEFINITION>` 再被替换为实际任务定义 ARN。这两个占位符不是可直接运行的镜像地址或 ARN。

## 当前配置中需要理解的限制

以下是学习当前项目时的观察，不是此次注释已完成的功能修复。

- 私有子网没有 NAT 默认路由，也没有在仓库中定义相应 VPC Endpoint。放行 ECS 出站安全组不能补足路由；镜像获取、日志发送和 ECS Exec 所需的访问路径还需要配置。
- 两个可用区不等于已有两份任务。初始任务数与扩缩容下限均为 1，一个任务不足以提供跨区冗余。
- 10443 测试入口的入站 CIDR 是 `0.0.0.0/0`，并没有限制为内部测试人员。Host 匹配规则也不是完整访问限制，因为 ALB 默认动作仍转发请求。
- 初始 Terraform 任务使用 `httpd:latest`，流水线发布的镜像来自 Nginx Dockerfile。两份任务模板并不完全一致。初始任务还把临时卷挂在容器 `/`，需要审查对镜像文件的影响；这不是已经配置好的持久化存储。
- ALB 的健康检查使用 `/`，构建测试与 Dockerfile 使用 `/health`。检查的路径不同，不能把其中一次成功当作另一条路径已经验证。
- CPU 和内存各配置了 step scaling 与 target tracking。理解策略时要一起阅读，不能把每条策略当成独立控制器；阈值和目标利用率需要通过实际负载验证。
- 多项 IAM 角色、VPC 和 state 桶以现有资源为前提，本仓库没有创建它们。Provider 的 `prd` profile 名称不能验证账号身份，固定 ARN 也限制了跨账号复用。
- state 使用 S3，但没有配置并发锁。不要把状态集中存储等同于多人并发执行已安全协调。
- CodePipeline 的人工审批负责决定是否开始部署；CodeDeploy 根据部署组设置执行 Blue/Green 切换。两者是不同阶段，观察发布进度时需要分别查看。
- ECR 不允许覆盖同标签，而构建用提交 ID 前 12 位作为标签。重复构建同一提交可能在 push 时失败；保留 30 个镜像也不能保证更早版本仍可回滚。
- `create_before_destroy` 配合固定名称可能遇到重名冲突。写了这个选项不能保证任何替换都无中断。

`terraform validate` 只校验配置结构和 Provider 接口，不能证明上述网络路径、权限或部署等待流程能够正常运行。读懂注释后，下一步应通过计划与实际验证逐项确认，而不是直接把当前值当作生产最佳实践。
