---
module: payment
status: living
code_paths:
  - src/modules/payment/
contract_entry: src/modules/payment/index.ts
last_updated: 2026-10-19
---

# 模块活态架构说明书：支付与账单 (Payment Module)

> 本文件代表 `payment` 模块**此时此刻的最新生产状态**。修改 `src/modules/payment/**` 前必读。
> 说明：本文件是脚手架随附的**示例占位**（与 `example-auth.md` 配套，用于演示 `00-INDEX.md` 的路由格式）。
> 接入真实项目时，请用真实模块文档替换本文件，或删除本文件与 `00-INDEX.md` 中对应行。

## 1. 模块职责与边界
- 负责支付单创建、支付渠道回调验签、退款、对账。
- **不负责**：订单状态机与商品价格计算（归属 `order` 模块）。

## 2. 对外暴露的公共契约 (Public Contracts)
其它模块仅允许调用 `src/modules/payment/index.ts` 中的以下方法：
- `createPayment(orderId: string, amount: number): Promise<PaymentResult>`
- `refund(paymentId: string, amount: number): Promise<RefundResult>`

## 3. 核心数据表结构摘要
- `payments`: 支付单主表（渠道、金额、状态、外部流水号）。
- `payment_refunds`: 退款流水，一张支付单可对应多条退款。

## 4. 本模块专属红线 (Module-Specific Guardrails)
1. 金额一律使用最小货币单位的整数，严禁浮点数参与计算。
2. 支付渠道回调必须先验签、再校验金额与商户号，最后才改状态；验签失败直接拒绝且不落库。
3. 重复回调必须幂等：以 `渠道流水号` 做唯一约束，重复请求返回既有结果。
4. 修改本模块任何文件后，必须运行：`bash scripts/ai-verify.sh <修改的文件路径>`
