# 几何 segment 属性计划

用于决定「几何」segment 最终要展示/编辑哪些属性。最后一列由你手动标记：
**不需要的属性填 `x`**，留空表示待定。

图例：

- 读写：`读/写` = 有公开 setter；`只读` = getter only；`方法` = 通过方法读写。
- 现有编辑器：2 格 = 点编辑器；数字 = `HierarchyNumberFieldView`；无 = 需要新增。
- 状态：已实现 / 待升级 / 候选新增。

---

## 1. 现状（已实现）

| 属性 | 类型 | 作用 | 读写 | 现有编辑器 | 状态 | 不需要做（手标） |
|---|---|---|---|---|---|---|
| `layer.position` | CGPoint | layer 在父 layer 坐标系中的位置，受 `anchorPoint` 影响 | 读/写 | 2 格 | 已实现 | |
| `layer.anchorPoint` | CGPoint | 锚点，默认 (0.5, 0.5)；影响 position 与旋转/缩放中心 | 读/写 | 2 格 | 已实现 | |
| `layer.zPosition` | CGFloat | layer 在 z 轴上的层级 | 读/写 | 数字 | 已实现 | |
| `layer.anchorPointZ` | CGFloat | 3D 锚点的 z 值 | 读/写 | 数字 | 已实现 | |
| `transform` | CGAffineTransform | 仿射变换；`frame` 由 bounds/center/transform 派生，transform 非 identity 时 frame 不可靠 | 读/写 | 无（当前只读文本） | 待升级 | |
| `transform3D` | CATransform3D | 3D 变换；iOS 上等价于 `layer.transform` | 读/写 | 无（当前只读文本） | 待升级 | |

---

## 2. 计划修改

### 2.1 `transform` 升级为 6 格编辑器

| 项 | 内容 |
|---|---|
| 输入 | `HierarchyNumberGridView`，labels：`a / b / c / d / tx / ty` |
| 写入 | `view.transform = CGAffineTransform(a:b:c:d:tx:ty:)` |
| 实现 | 内置行已有自定义 `input` / `write`，不需要新增 `ValueKind` |
| 注意 | transform 非 identity 时 `frame` 不可靠；编辑后 frame 行会跟着变 |
| 建议 | 可做 |

### 2.2 `transform3D` 改为矩阵展示

| 项 | 内容 |
|---|---|
| 展示 | 4×4 矩阵，`m11 … m44`，只读 |
| 编辑 | 不提供；16 个值误操作成本高，且与 `transform` 重叠 |
| 实现 | `.text(...)`，用格式化函数拼接 |
| 建议 | 只读展示 |

---

## 3. 候选新增

| 属性 | 类型 | 作用 | 读写 | 建议 | 不需要做（手标） |
|---|---|---|---|---|---|
| `layer.bounds` | CGRect | layer 自身坐标系中的矩形；正常情况下与 `view.bounds` 一致 | 读/写 | 只读展示，用于确认 transform 后的实际值 | |
| `layer.frame` | CGRect | 由 position / bounds / anchorPoint / transform 派生 | 读/写 | 只读展示，与 `view.frame` 对照 | |
| `layer.isGeometryFlipped` | Bool | 子 layer 的 y 轴是否翻转 | 读/写 | 只读展示；极冷门 | |
| `layer.affineTransform()` | CGAffineTransform | 从 `layer.transform` 提取的仿射部分 | 方法 | 只读展示；与 `transform` 重复，可不要 | |

---

## 4. 明确不做

| 属性 | 原因 |
|---|---|
| `layer.cornerRadius` / `borderWidth` / `shadow*` | 外观/描边，不属于布局几何 |
| `layer.contentsScale` / `rasterizationScale` / `shouldRasterize` | 渲染相关，不影响布局 |
| `layer.mask` / `sublayers` / `subLayerTransform` | 模型结构，不是标量属性 |
| `view.center` / `frame` / `bounds` | 已在 Auto Layout 段展示，避免重复 |
| `layer.position` / `anchorPoint` 的 3D 扩展 | 当前已覆盖 `anchorPointZ`，其余无公开 API |
