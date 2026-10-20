# 架构活文档路由表 (Deterministic Context Router)

> **AI 检索唯一起点**：根据你即将修改的代码路径，在下表中定位对应的模块活文档。
> **严禁**加载与当前任务无关的模块文档！**严禁**读取 `docs/specs/archive/` 下的历史过程文档！

| 业务模块 (Module) | 绑定的代码路径 (Code Paths) | 跨模块只读契约入口 (Public Contract) | 对应的活态架构与局部规则文档 |
| :--- | :--- | :--- | :--- |
| **全局领域边界** | `src/**` (涉及跨模块通信时) | `src/shared/types/**` | `docs/architecture/domain-map.md` |
| **认证与权限 (示例)** | `src/modules/auth/**` | `src/modules/auth/index.ts` | `docs/architecture/modules/example-auth.md` |
| **支付与账单 (示例)** | `src/modules/payment/**` | `src/modules/payment/index.ts` | `docs/architecture/modules/example-payment.md` |

---
## 路由表维护规范
1. 每当新增业务模块时，必须在 `docs/architecture/modules/` 下创建对应文档，并在此表登记。
2. 每次 `docs/specs/active/<feat>` 开发完成并合入主干前，必须按 `.agents/skills/archive-spec.md` 将架构变更同步到上表对应的模块文档中。
