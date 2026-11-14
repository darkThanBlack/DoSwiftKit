# 代码风格检查（注释与文件头）

面向「定期执行检查的 LLM」写的一份可执行清单：规则都是确定性的，先跑脚本，再按第 3 节
处理脚本无法判断的那一类。

## 1. 执行方式

```bash
Scripts/check-code-style.sh        # 退出码 0 = 通过，1 = 有违规
```

输出每行一条，制表符分隔：

```
R2	Code/Foo/Bar.swift:16	10 lines: /// User-facing copy: one `NSLocalizedString` per property,
```

最后一行为 `-- N violation(s)`，写到 stderr。**只看 stdout 的 `R*` 行。**
脚本扫描 `Code/`、`Tests/`、`Scripts/` 下所有 `.swift`，跳过 `.git`、`.build`、`Example`、
`Pods`、`.swiftpm`。

## 2. 规则（脚本判定）

### R1 文件头

每个 Swift 文件开头固定十行，必须逐字符一致：

```swift
//
//  <文件名>.swift
//  DoSwift
//
//  Created by moonShadow on yyyy/MM/dd
//  Copyright © yyyy darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//
```

| 判定点 | 要求 |
|---|---|
| 文件名行 | 等于实际文件名，含扩展名 |
| 作者 | 固定 `moonShadow`，不写其他名字 |
| 日期 | 创建日期，`yyyy/MM/dd` 补零 |
| 版权年份 | 与创建日期的年份相同（2025 年创建的文件写 `© 2025`） |
| 第 6/8/9 行 | 逐字照抄模板，不增删空行 |
| 例外 | `Package.swift` 首行必须是 `// swift-tools-version:`，豁免 |

### R2 注释一到两行

连续的 `//` 或 `///` 行算一个块（`// MARK:` 不计入）。**一个块最多两行。**
文件头不计。多行注释的写法是合并句子，不是把三句挤成两行长句：

```swift
// 违规：三行
/// Constraints involving `view`, walking the selected view and its ancestors.
/// The result is sorted by creation order, so the equation index matches
/// what the runtime prints.

// 合规：两行，只留结论和理由
/// Constraints involving `view` and its ancestors, in creation order so the
/// equation index matches what the runtime prints.
```

### R3 注释用英文

注释里不允许出现 CJK 字符（`㐀-䶿`、`一-鿿`）。空行、`// MARK:`、文件头不参与判断。
Apple API 名、协议名、单位、缩写保持英文原词；带参数的文案模板放在 `.strings`，不写进注释。

## 3. 需要判断的规则（脚本不判）

### R4 注释解释「为什么」，不复述代码

逐条读改动过的注释，命中任意一条就算违规：

- 与下一行代码同义：`// set the title` 后面跟 `titleLabel.text = title`
- 描述显而易见的实现步骤：`// 遍历数组`、`// 返回结果`
- 记录「本次修改了什么」而不是「为什么这样」：`// 新增 XXX`、`// fixed bug`
- 重复类型或参数名已经说明的信息

合规的写法是给约束、给原因、给取舍：

```swift
// `0` means no limit: the tree runs up to the topmost ancestor.
// Written without a table reload: rebuilding sections drops the keyboard.
```

## 4. 存量与执行策略

2026-11-14 首次运行时，R1 / R3 全仓通过，R2 有 **25 处存量违规**，分布如下：

| 文件 | 块数 |
|---|---|
| `Code/MainMenu/Core.swift` | 3 |
| `Code/Hierarchy/HierarchyPropertyEngine.swift` | 3 |
| `Code/Runtime/Swizzler.swift` | 2 |
| `Code/Network/NetworkCapture.swift` | 2 |
| `Code/Hierarchy/HierarchyConstraintEngine.swift` | 2 |
| 其余 13 个文件各 1 处 | 13 |

执行策略：

1. **本次新增或修改的代码必须零违规**，用 `git diff --name-only <基线提交>...HEAD` 取范围，
   脚本里没有基线概念，自行比对。
2. 存量违规只做顺手清理：改到某个文件时，把它那几块压到两行；不要在无关提交里批量重排。
3. 修完重跑脚本，确认退出码为 0，或只剩未被本次改动触碰的存量文件。

## 5. 报告格式

检查完成后按下面结构汇报，便于人快速扫：

```markdown
## 风格检查 <提交>

| 规则 | 位置 | 现状 | 建议 |
|---|---|---|---|
| R2 | Code/Foo/Bar.swift:16 | 5 行注释 | 合并为两行：保留「为什么」那句 |
| R4 | Code/Foo/Baz.swift:88 | `// set the title` | 删除，代码已自解释 |

- 脚本：25 → 23（本次新增 0，清理 2）
- 未处理：`Code/Network/NetworkCapture.swift` 两处属于另一个改动的范围
```

## 6. 改动边界

- 只动注释，不改代码逻辑、不动字符串、不调格式。
- `// MARK:` 行、`#if` / `#else` 之间的注释按普通注释处理，但不要为了压行而删掉 MARK 分组。
- 文件头已经正确时**不要**重排或补空行；只在 R1 报告的文件上改。
- 注释语言只允许英文，但「英文」不等于改写原意：压缩时优先删掉复述代码的那半句。
