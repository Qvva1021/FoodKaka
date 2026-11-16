# FoodKaKa 图片转发服务

只接收当前餐食图片、调用已配置的视觉模型并校验结果。不保存个人资料、饮食记录或照片，不打印密钥或图片内容。

## 本机启动

在项目根目录执行（本项目已使用 `.tools/server-venv` 创建独立环境）：

```powershell
python -m venv .tools/server-venv
.\.tools\server-venv\Scripts\python.exe -m pip install -r server/requirements-lock.txt
Copy-Item server/.env.example server/.env
```

若已有 `.env`，不要再次覆盖。编辑本地 `server/.env`：

1. 用随机字符串设置 `FOODKAKA_TOKEN`（至少 24 字符），这是手机访问电脑的个人令牌，区别于模型 API 密钥。
2. 选择 `AI_PROVIDER=gemini` 或 `openrouter`。
3. 模型密钥只填电脑端 `.env`，不要放进 APK、源码、截图或聊天；`.env` 已忽略。

生成个人令牌可在自己的终端运行：

```powershell
python -c "import secrets; print(secrets.token_urlsafe(24))"
```

先做本机测试：

```powershell
.\.tools\server-venv\Scripts\python.exe -m uvicorn server.app:app --host 127.0.0.1 --port 8000 --no-access-log
```

手机与电脑同一局域网时，用 `--host 0.0.0.0` 代替 `127.0.0.1`。只在自己信任的局域网使用，不做公网端口映射；如果 Windows 防火墙提示，按自己的私有网络环境配置访问。

手机进入「我的 → AI 服务连接与测试」，填写 `http://电脑局域网IP:8000` 与 `FOODKAKA_TOKEN`，保存并测试。Android 模拟器连接宿主电脑可使用 `http://10.0.2.2:8000`。测试会区分“电脑服务连通”和“模型配置是否就绪”，不会假称模型已经识别成功。

## 免费模型策略

- Gemini：默认 `gemini-3.5-flash-lite`，另允许 `gemini-3.1-flash-lite`。截至核对日期 2026-11-16，官方价格页列出其免费层。必须确认自己的项目未开启计费，然后设置 `GEMINI_FREE_TIER_CONFIRMED=true`。代码不能代替账户控制台证明计费状态，不能使用已启用付费计费的项目冒充免费层。
- OpenRouter：填写当前账号实际可用、支持图片输入且以 `:free` 结尾的模型 ID。每次识别前核对公开模型目录中的输入模态和价格；请求禁用提供方回退，价格上限为零。不使用付费模型或自动模型回退列表。
- 配额不足、认证/地区问题和服务错误会直接提示，不自动重试收费请求，不自动切换到付费模型。
- 默认配置不具备真实识别能力；缺少密钥或免费层确认时拒绝识别。手动记账始终可用。

Gemini 的官方支持地区列表未包含中国大陆，不能承诺在国内电脑上直连可用；备用服务也必须用实际账号和网络验证。不要为了运行本项目购买服务器或 API 套餐。

## 图片与接口

- `GET /health`：需要 `Authorization: Bearer <FOODKAKA_TOKEN>`；返回服务状态、模型配置是否就绪和提示。不会调用模型验证额度。
- `POST /recognize`：同样需要个人令牌，直接上传图片二进制，Content-Type 为 `image/jpeg`、`image/png` 或 `image/webp`；不是 multipart 表单。
- 图片最大 5 MB，限制解码像素数与格式，缩放并重新编码为 JPEG，移除 EXIF，内存中处理。
- 返回 `foods`、按明细计算的 `total_calories` 和 `notes`。只容忍一次本地去 Markdown 围栏修复，不额外请求模型修复 JSON。
- 后端不会写入客户端 SQLite。识别完成后手机仍需修改/确认，用户按下「确认保存」才入账。

个人局域网 HTTP 传输未加密，只适用于可信家庭网络；外网服务须使用 HTTPS，客户端拒绝外网 HTTP 地址与重定向。第三方免费服务可能将图片用于产品改进，客户端首次识别前会明确提示；使用前应自行确认所选服务最新条款。

## 测试

```powershell
.\.tools\server-venv\Scripts\python.exe -m unittest server.test_app -v
```

测试使用本地生成的图片与模拟上游响应，不消耗 API 额度。真实模型验收需要可用的免费账号、密钥和支持的网络环境，不能用这些测试替代。

## 官方参考

- [Gemini 图像理解](https://aistudio.google.com/docs/image-understanding)
- [Gemini 价格与免费层](https://aistudio.google.com/docs/pricing#gemini-3.5-flash-lite)
- [Gemini 支持地区](https://aistudio.google.com/docs/available-regions)
- [OpenRouter 免费模型规则](https://openrouter.ai/docs/guides/routing/model-variants/free)
