# 构建与部署配置逐行说明

[日本語版](deployment-line-by-line.ja.md)

这里保留原文件，按原始行号解释作用与理由。空行只是分组；括号、缩进和 YAML 的短横线用于表达结构。具体的历史设计动机没有依据时，说明当前行为和取舍。

## Dockerfile

原文件：[Dockerfile](../Dockerfile)

| 行号 | 原代码 | 作用与设计理由 |
| --- | --- | --- |
| 1 | <code>FROM nginx:1.27-alpine</code> | 作用：以 Nginx Alpine 镜像为基础。理由：演示应用是静态页面，用 Web 服务器即可配合较小的镜像；1.27 是当前文件固定的版本系列，并未锁定 digest。 |
| 2 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 3 | <code>COPY app/index.html /usr/share/nginx/html/index.html</code> | 作用：把首页复制进 Nginx 默认站点目录。理由：使用镜像内的文件发布，让镜像版本与页面版本对应。 |
| 4 | <code>COPY app/health /usr/share/nginx/html/health</code> | 作用：复制健康检查文件。理由：让 /health 返回固定内容，供构建测试和容器健康检查读取；这是静态文件检查，不检查数据库等后端依赖。 |
| 5 | <code>COPY app/styles.css /usr/share/nginx/html/styles.css</code> | 作用：复制页面样式。理由：页面引用该文件，需要与首页一起进入镜像，否则显示会缺少样式。 |
| 6 | <code>COPY app/momo-hero.png /usr/share/nginx/html/momo-hero.png</code> | 作用：复制页面图片。理由：保证容器独立运行时能提供页面引用的图像资源。 |
| 7 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 8 | <code>EXPOSE 80</code> | 作用：声明容器使用 80 端口。理由：向使用者描述应用端口；它不会自己发布宿主机端口，实际映射由 docker run 或 ECS 配置完成。 |
| 9 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 10 | <code>HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \</code> | 作用：每 30 秒检测一次，单次限 3 秒，启动宽限 5 秒，连续失败 3 次判为不健康。理由：通过间隔与重试减少偶发错误误判；行尾反斜杠让下一行成为同一条指令。 |
| 11 | <code>CMD wget --quiet --tries=1 --spider http://127.0.0.1/health &#124;&#124; exit 1</code> | 作用：从容器内部探测健康路径，失败返回退出码 1。理由：使用 wget 检查 HTTP 可达性；不核对返回内容是否为 OK。这里是 HEALTHCHECK 的 CMD，不是另一个容器启动命令。 |

## buildspec.yml

原文件：[buildspec.yml](../buildspec.yml)

| 行号 | 原代码 | 作用与设计理由 |
| --- | --- | --- |
| 1 | <code>version: 0.2</code> | 作用：选择 CodeBuild buildspec 0.2 格式。理由：让同次构建的 shell 命令能共享前面设置的变量和环境，便于传递镜像地址。 |
| 2 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 3 | <code>env:</code> | 作用：开始构建环境配置。理由：与具体构建阶段分开说明命令运行的 shell 环境。 |
| 4 | <code>shell: bash</code> | 作用：使用 Bash。理由：后续使用提交 ID 截取、循环和 pipefail 等 Bash 语法。 |
| 5 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 6 | <code>phases:</code> | 作用：开始构建阶段列表。理由：按准备、构建、收尾分组，便于定位失败发生在哪一步。 |
| 7 | <code>pre_build:</code> | 作用：定义构建前准备阶段。理由：先登录 ECR 并确定镜像标签，再构建镜像。 |
| 8 | <code>commands:</code> | 作用：开始当前阶段的命令列表。理由：每个 YAML 列表项交给 shell 执行，缩进决定命令属于哪个阶段。 |
| 9 | <code>- aws --version</code> | 作用：打印 AWS CLI 版本。理由：日志中保留工具信息，帮助排查构建环境差异。 |
| 10 | <code>- aws ecr get-login-password --region "$AWS_DEFAULT_REGION" &#124; docker login --username AWS --password-stdin "$ECR_REGISTRY"</code> | 作用：读取 ECR 登录密码并通过标准输入交给 Docker。理由：使用 CodeBuild 角色而非源码中的静态密码；区域和 registry 地址必须对应。 |
| 11 | <code>- IMAGE_TAG="${CODEBUILD_RESOLVED_SOURCE_VERSION:0:12}"</code> | 作用：取本次源版本前 12 位作为标签。理由：让镜像可关联到提交；短标签并不绝对唯一，ECR 不可变标签也会阻止同标签重复推送。 |
| 12 | <code>- IMAGE_URI="$ECR_REPOSITORY_URI:$IMAGE_TAG"</code> | 作用：拼出 仓库地址:标签。理由：后续 build、run、push 使用同一镜像标识，避免测试一个版本却上传另一个。 |
| 13 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 14 | <code>build:</code> | 作用：开始构建和测试阶段。理由：通过测试后才生成允许上传的标记。 |
| 15 | <code>commands:</code> | 作用：开始当前阶段的命令列表。理由：每个 YAML 列表项交给 shell 执行，缩进决定命令属于哪个阶段。 |
| 16 | <code>- docker build --tag "$IMAGE_URI" .</code> | 作用：使用当前目录的 Dockerfile 构建镜像并标记地址。理由：代码、静态资源和健康检查文件一并进入本次镜像。 |
| 17 | <code>- docker run --detach --name test-app --publish 8080:80 "$IMAGE_URI"</code> | 作用：后台运行刚构建的镜像，将构建机 8080 映射到容器 80。理由：从容器外测试 HTTP，接近真实服务访问方式；固定名称便于最后清理。 |
| 18 | <code>- &#124;</code> | 作用：把下面多行作为一条 YAML 字面块命令。理由：循环与条件判断要在同一个 Bash 脚本上下文执行。 |
| 19 | <code>set -o pipefail</code> | 作用：让管道中任一命令失败也反映在管道退出码。理由：curl 请求失败不能被管道末尾程序的结果掩盖。 |
| 20 | <code>for i in {1..10}; do</code> | 作用：最多尝试 10 次。理由：容器启动需要短暂时间，用有限重试避免立即误判或无限等待。 |
| 21 | <code>if curl --fail --silent http://127.0.0.1:8080/health &#124; grep --quiet '^OK$'; then</code> | 作用：请求测试容器健康端点，并核对返回内容含有整行 OK。理由：同时检测 HTTP 成功和预期内容；if 根据管道退出码判断是否通过。 |
| 22 | <code>echo "Health check passed"</code> | 作用：打印健康检查通过。理由：让构建日志明确记录测试结论。 |
| 23 | <code>break</code> | 作用：退出重试循环。理由：第一次成功就继续构建，不等待剩余次数。 |
| 24 | <code>fi</code> | 作用：结束当前 if 判断。理由：Bash 用 fi 配对 if，保证成功路径与失败路径属于正确范围。 |
| 25 | <code>if [ "$i" -eq 10 ]; then</code> | 作用：判断是否已到最后一次尝试。理由：只有耗尽次数后才判定测试失败，前面失败允许重试。 |
| 26 | <code>echo "Health check failed"</code> | 作用：打印最终失败信息。理由：在构建日志中指出停止的原因。 |
| 27 | <code>exit 1</code> | 作用：以非零退出码结束脚本。理由：告诉 CodeBuild 测试失败，阻止后续将失败镜像当作通过验证的产物。 |
| 28 | <code>fi</code> | 作用：结束当前 if 判断。理由：Bash 用 fi 配对 if，保证成功路径与失败路径属于正确范围。 |
| 29 | <code>sleep 2</code> | 作用：失败后等待 2 秒。理由：给服务启动时间并避免密集请求；这不是精确的整体 20 秒上限，请求本身也耗时，curl 没配置单次超时。 |
| 30 | <code>done</code> | 作用：结束 for 循环。理由：后续通过标记属于循环外步骤，只有循环正常退出后才执行。 |
| 31 | <code>- touch /tmp/health-check-passed</code> | 作用：创建测试成功标记文件。理由：post_build 通过文件是否存在确认成功路径已走完；前面最后一次失败的 exit 1 会阻止此行执行。 |
| 32 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 33 | <code>finally:</code> | 作用：定义构建阶段的收尾命令。理由：测试失败时也应清理运行中的测试容器。 |
| 34 | <code>- docker rm --force test-app &#124;&#124; true</code> | 作用：强制删除测试容器，失败时用 true 保持成功退出。理由：容器未创建等清理异常不应覆盖原本的测试失败信息。 |
| 35 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 36 | <code>post_build:</code> | 作用：进入镜像上传与产物生成阶段。理由：此处仍显式检查成功标记，避免前面失败却继续推送。 |
| 37 | <code>commands:</code> | 作用：开始当前阶段的命令列表。理由：每个 YAML 列表项交给 shell 执行，缩进决定命令属于哪个阶段。 |
| 38 | <code>- test -f /tmp/health-check-passed</code> | 作用：验证成功标记是文件。理由：缺少标记时命令失败，使上传前有明确的测试门槛。 |
| 39 | <code>- docker push "$IMAGE_URI"</code> | 作用：将已测试镜像上传到 ECR。理由：Fargate 从镜像仓库获取部署版本，而不是从构建机器获取。 |
| 40 | <code>- printf '{"ImageURI":"%s"}' "$IMAGE_URI" &gt; imageDetail.json</code> | 作用：输出包含 ImageURI 的 JSON。理由：CodePipeline 的 ECS Blue/Green 部署动作从该文件读取实际镜像地址，并替换任务模板占位符。 |
| 41 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 42 | <code>artifacts:</code> | 作用：定义 CodeBuild 交给流水线的文件产物。理由：镜像放在 ECR，部署模板和镜像地址文件通过流水线产物传递。 |
| 43 | <code>files:</code> | 作用：列出要纳入产物的文件。理由：后续 Deploy 动作只能读取被打包进产物的文件。 |
| 44 | <code>- appspec.yaml</code> | 作用：将 CodeDeploy 部署说明加入产物。理由：说明目标容器端口及新任务定义的引用。 |
| 45 | <code>- taskdef.json</code> | 作用：将 ECS 任务定义模板加入产物。理由：Deploy 动作替换镜像占位符后注册新 revision。 |
| 46 | <code>- imageDetail.json</code> | 作用：将本次构建的镜像 URI 文件加入产物。理由：把已测试、已上传的镜像准确传给部署动作。 |

## appspec.yaml

原文件：[appspec.yaml](../appspec.yaml)

| 行号 | 原代码 | 作用与设计理由 |
| --- | --- | --- |
| 1 | <code>version: 0.0</code> | 作用：声明 CodeDeploy AppSpec 格式版本。理由：这是 AppSpec 的版本，与 buildspec 的 0.2、应用发布版本均不同。 |
| 2 | <code>Resources:</code> | 作用：开始需要部署的资源列表。理由：AppSpec 使用自己的大小写与结构，不能按 buildspec 格式填写。 |
| 3 | <code>- TargetService:</code> | 作用：声明这次更新的 ECS 目标服务配置。理由：提供任务定义及负载均衡所需的容器信息。 |
| 4 | <code>Type: AWS::ECS::Service</code> | 作用：说明目标类型为 ECS 服务。理由：让 CodeDeploy 使用 ECS 部署流程，而非 EC2 文件复制流程。 |
| 5 | <code>Properties:</code> | 作用：开始目标服务的部署属性。理由：将任务定义、端口及平台配置归到同一个目标下。 |
| 6 | <code>TaskDefinition: &lt;TASK_DEFINITION&gt;</code> | 作用：预留任务定义 ARN 占位符。理由：流水线注册新的 revision 后才能得到 ARN，因此不在模板中硬编码旧 revision。 |
| 7 | <code>LoadBalancerInfo:</code> | 作用：定义目标容器与端口。理由：CodeDeploy 要知道新任务集的哪个容器接收负载均衡流量。 |
| 8 | <code>ContainerName: zhu-prd-container-test2</code> | 作用：指定要注册到目标组的容器名称。理由：必须与 taskdef.json 中的 name 完全一致，否则找不到目标容器。 |
| 9 | <code>ContainerPort: 80</code> | 作用：把负载均衡流量交给容器 80。理由：与 Nginx、ECS 端口映射及 ALB 目标组保持一致。 |
| 10 | <code>PlatformVersion: 1.4.0</code> | 作用：固定部署使用的 Fargate 平台版本。理由：使运行环境明确，升级平台时应与 Terraform 初始服务配置一并检查。 |

## taskdef.json

原文件：[taskdef.json](../taskdef.json)

| 行号 | 原代码 | 作用与设计理由 |
| --- | --- | --- |
| 1 | <code>{</code> | 开始 JSON 对象，字段以键值对表示；嵌套对象在这里用于定义一个容器或一条端口映射。 |
| 2 | <code>"family": "zhu-prd-ecs-test2",</code> | 给任务定义的多个 revision 使用同一 family，让部署版本归属于同一应用。 |
| 3 | <code>"executionRoleArn": "arn:aws:iam::043300555595:role/zhu-prd-ecs-task-execution-role",</code> | 指定现有执行角色，供 ECS 拉取镜像和写日志；不等于应用自身调用 AWS API 的角色。 |
| 4 | <code>"taskRoleArn": "arn:aws:iam::043300555595:role/zhu-prd-ecs-task-role",</code> | 指定应用任务角色，给运行中的容器提供 AWS API 权限；需提前创建并配置最小必要权限。 |
| 5 | <code>"networkMode": "awsvpc",</code> | 使用 awsvpc，给任务独立网卡和 IP，以任务安全组限制访问。 |
| 6 | <code>"requiresCompatibilities": ["FARGATE"],</code> | 要求任务兼容 FARGATE，避免依赖自己管理的 EC2 宿主机。 |
| 7 | <code>"cpu": "256",</code> | 设置 256 CPU 单位；任务级对应 0.25 vCPU，容器级表示容器的 CPU 分配。作为起步规格，需结合负载验证。 |
| 8 | <code>"memory": "512",</code> | 给整个任务分配 512 MiB 内存，与 CPU 规格共同定义 Fargate 资源档位。 |
| 9 | <code>"runtimePlatform": {</code> | 开始运行平台对象，明确镜像所需操作系统和处理器架构。 |
| 10 | <code>"operatingSystemFamily": "LINUX",</code> | 选择 Linux，匹配 Nginx Alpine 镜像。 |
| 11 | <code>"cpuArchitecture": "X86_64"</code> | 选择 X86_64；构建输出的镜像也需要匹配此架构，不能直接用仅支持 ARM 的镜像。 |
| 12 | <code>},</code> | 结束当前 JSON 对象或列表；逗号分隔后续元素，最后一个元素后不允许多余逗号。 |
| 13 | <code>"containerDefinitions": [</code> | 开始容器定义列表；一个任务可有多个容器，当前只有一个。 |
| 14 | <code>{</code> | 开始 JSON 对象，字段以键值对表示；嵌套对象在这里用于定义一个容器或一条端口映射。 |
| 15 | <code>"name": "zhu-prd-container-test2",</code> | 指定容器名，必须与 AppSpec 的 ContainerName 和 ECS 服务绑定名称一致。 |
| 16 | <code>"image": "&lt;IMAGE1_NAME&gt;",</code> | 预留 <IMAGE1_NAME>，由流水线用 imageDetail.json 的实际 ECR URI 替换；该占位符本身不是可拉取镜像。 |
| 17 | <code>"essential": true,</code> | 设为必要容器；容器退出会影响整个任务的正常运行状态。 |
| 18 | <code>"cpu": 256,</code> | 设置 256 CPU 单位；任务级对应 0.25 vCPU，容器级表示容器的 CPU 分配。作为起步规格，需结合负载验证。 |
| 19 | <code>"memoryReservation": 512,</code> | 为容器预留 512 MiB 内存；这是软预留，任务的 memory 另外限定任务级内存。 |
| 20 | <code>"portMappings": [</code> | 开始端口映射列表，使 ECS 与负载均衡器能关联容器入口。 |
| 21 | <code>{</code> | 开始 JSON 对象，字段以键值对表示；嵌套对象在这里用于定义一个容器或一条端口映射。 |
| 22 | <code>"containerPort": 80,</code> | 暴露容器内 80，与 Nginx 的监听端口一致。 |
| 23 | <code>"hostPort": 80,</code> | 使用相同的 80 端口，匹配 awsvpc 模式下的映射。 |
| 24 | <code>"protocol": "tcp"</code> | 使用 TCP，与 HTTP 请求所用的传输协议一致。 |
| 25 | <code>}</code> | 结束当前 JSON 对象或列表；逗号分隔后续元素，最后一个元素后不允许多余逗号。 |
| 26 | <code>],</code> | 结束当前 JSON 对象或列表；逗号分隔后续元素，最后一个元素后不允许多余逗号。 |
| 27 | <code>"logConfiguration": {</code> | 开始日志配置，将容器输出送往集中日志而非仅保存在任务内。 |
| 28 | <code>"logDriver": "awslogs",</code> | 选择 awslogs，让日志进入 CloudWatch，便于在任务退出后排查问题。 |
| 29 | <code>"options": {</code> | 开始日志驱动选项，指定日志组、区域和流名前缀。 |
| 30 | <code>"awslogs-group": "/ecs/zhu-prd-ecs-test2",</code> | 指定 ECS 模块创建的日志组，保持日志目标一致；名称相同不能证明 IAM 与网络访问已满足。 |
| 31 | <code>"awslogs-region": "ap-northeast-1",</code> | 将日志发送到东京区域，与当前 ECS 环境一致。 |
| 32 | <code>"awslogs-stream-prefix": "ecs"</code> | 使用 ecs 日志流前缀，配合容器名和任务 ID 区分各任务日志。 |
| 33 | <code>}</code> | 结束当前 JSON 对象或列表；逗号分隔后续元素，最后一个元素后不允许多余逗号。 |
| 34 | <code>}</code> | 结束当前 JSON 对象或列表；逗号分隔后续元素，最后一个元素后不允许多余逗号。 |
| 35 | <code>}</code> | 结束当前 JSON 对象或列表；逗号分隔后续元素，最后一个元素后不允许多余逗号。 |
| 36 | <code>]</code> | 结束当前 JSON 对象或列表；逗号分隔后续元素，最后一个元素后不允许多余逗号。 |
| 37 | <code>}</code> | 结束当前 JSON 对象或列表；逗号分隔后续元素，最后一个元素后不允许多余逗号。 |

## common/prd_test2/prd.tfvars.example

原文件：[common/prd_test2/prd.tfvars.example](../common/prd_test2/prd.tfvars.example)

| 行号 | 原代码 | 作用与设计理由 |
| --- | --- | --- |
| 1 | <code># 環境固有の値を入力してから prd.tfvars として保存する。</code> | 说明需要填入真实环境值后再保存为 prd.tfvars；example 不是可直接套用的网络规划。 |
| 2 | <code>ecs_a_subnet_cidr        = "10.x.x.x/24"</code> | 填写第一个 ECS 子网 CIDR；10.x.x.x/24 是占位文字，必须替换为现有 VPC 内的有效、不重叠范围。 |
| 3 | <code>ecs_c_subnet_cidr        = "10.x.x.x/24"</code> | 填写第二个 ECS 子网 CIDR；应与第一个子网不同，并在 VPC 地址范围内。 |
| 4 | <code>github_repository = "syumanro/terraform-aws-api-platform"</code> | 指定 GitHub 仓库；流水线源码动作读取这里指定的项目。 |
| 5 | <code>github_branch     = "main"</code> | 指定监控分支 main；该分支变更用于触发后续构建与部署。 |
| 6 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 7 | <code># 既存接続を再利用する場合のみ指定する。未指定なら Terraform が接続を作成する。</code> | 说明已有连接可复用；未指定时 Terraform 创建连接，但仍需在控制台完成 GitHub 授权。 |
| 8 | <code># github_connection_arn = "arn:aws:codeconnections:ap-northeast-1:123456789012:connection/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"</code> | 给出连接 ARN 的填写格式；本行被 # 注释，不参与执行，示例账号和 UUID 必须替换为真实值。 |

## scripts/preview.ps1

原文件：[scripts/preview.ps1](../scripts/preview.ps1)

| 行号 | 原代码 | 作用与设计理由 |
| --- | --- | --- |
| 1 | <code>$ErrorActionPreference = "Stop"</code> | 脚本出错时立即停止，避免文件读取等错误后仍继续提供不完整响应。 |
| 2 | <code>$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\app"))</code> | 由脚本目录计算 app 的绝对路径，使从不同工作目录启动都能找到静态文件。 |
| 3 | <code>$listener = [System.Net.HttpListener]::new()</code> | 创建 .NET HTTP 监听器，提供无需构建镜像的本地预览。 |
| 4 | <code>$listener.Prefixes.Add("http://localhost:8080/")</code> | 绑定 localhost:8080，仅供本机浏览器预览；这与 Docker 端口映射是两种独立的预览方式。 |
| 5 | <code>$listener.Start()</code> | 启动监听，后续才能等待浏览器请求。 |
| 6 | <code>Write-Host "Preview: http://localhost:8080/"</code> | 打印预览地址，让使用者知道应打开哪个 URL。 |
| 7 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 8 | <code>$contentTypes = @{</code> | 开始扩展名与 MIME 类型的映射表，让浏览器按正确类型解释文本资源。 |
| 9 | <code>".html" = "text/html; charset=utf-8"</code> | HTML 使用 text/html 和 UTF-8，支持页面文本正常显示。 |
| 10 | <code>".css"  = "text/css; charset=utf-8"</code> | CSS 使用 text/css 和 UTF-8，让浏览器按样式表解析。 |
| 11 | <code>".js"   = "application/javascript; charset=utf-8"</code> | JS 使用 JavaScript 类型和 UTF-8，供后续增加脚本时使用。 |
| 12 | <code>}</code> | 结束 MIME 映射表；图片和无扩展名健康文件未在此表显式声明类型。 |
| 13 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 14 | <code>try {</code> | 开始 try 块，配合 finally 在退出时停止监听器。 |
| 15 | <code>while ($listener.IsListening) {</code> | 监听器运行期间循环处理请求；这是简单串行预览服务，不是生产 Web 服务器。 |
| 16 | <code>$context = $listener.GetContext()</code> | 阻塞等待下一次请求，取得本次请求和响应对象。 |
| 17 | <code>$relativePath = $context.Request.Url.AbsolutePath.TrimStart("/")</code> | 取 URL 路径并去掉开头斜杠，转成相对文件路径。 |
| 18 | <code>if ([string]::IsNullOrWhiteSpace($relativePath)) { $relativePath = "index.html" }</code> | 访问根路径时使用 index.html，提供默认首页。 |
| 19 | <code>$filePath = [System.IO.Path]::GetFullPath((Join-Path $root $relativePath))</code> | 把相对路径转为完整路径，准备定位磁盘文件。 |
| 20 | （空行） | 空行用于分组、便于阅读，不参与执行。 |
| 21 | <code>if ($filePath.StartsWith($root) -and [System.IO.File]::Exists($filePath)) {</code> | 检查路径以 app 路径开头且文件存在；意图是约束到站点目录，但单纯字符串前缀检查缺少目录边界判断，不应直接照搬为生产安全校验。 |
| 22 | <code>$bytes = [System.IO.File]::ReadAllBytes($filePath)</code> | 读取完整文件为字节数组，便于直接输出 HTML、样式或图片。 |
| 23 | <code>$extension = [System.IO.Path]::GetExtension($filePath)</code> | 取得扩展名，为响应选择 MIME 类型。 |
| 24 | <code>$context.Response.ContentType = $contentTypes[$extension]</code> | 按映射表设置 Content-Type；表中没有的扩展名会缺少对应类型设置。 |
| 25 | <code>$context.Response.StatusCode = 200</code> | 返回 HTTP 200，表示文件请求成功。 |
| 26 | <code>$context.Response.OutputStream.Write($bytes, 0, $bytes.Length)</code> | 把字节写入响应输出流，向浏览器发送文件内容。 |
| 27 | <code>} else {</code> | 文件不存在或路径检查不通过时进入另一分支。 |
| 28 | <code>$context.Response.StatusCode = 404</code> | 返回 HTTP 404，告诉浏览器资源未找到。 |
| 29 | <code>}</code> | 结束文件是否可读取的分支判断。 |
| 30 | <code>$context.Response.Close()</code> | 关闭本次响应，通知浏览器本次请求已发送完毕。 |
| 31 | <code>}</code> | 结束循环体，准备处理下一次请求。 |
| 32 | <code>} finally {</code> | 结束 try 并进入 finally，即使异常退出也执行清理。 |
| 33 | <code>$listener.Stop()</code> | 停止监听器，释放本地监听资源。 |
| 34 | <code>}</code> | 结束 finally 块，脚本的监听生命周期结束。 |

