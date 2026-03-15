# Swift async/await 异步编程 Demo

## 简介

本 demo 展示 Swift 5.5+ 引入的 async/await 异步编程语法。这是 Swift 并发编程的重大升级，让异步代码像同步代码一样简洁易读。

## 基本原理

### 什么是 async/await？

在 async/await 之前，Swift 使用**回调（callback）**来处理异步操作：

```swift
// 传统的回调方式
func fetchUser(completion: @escaping (String?) -> Void) {
    // 异步操作
    completion("Tom")
}

fetchUser { user in
    print(user ?? "无")
}
```

async/await 的核心思想是：**让异步代码看起来像同步代码**：

```swift
// async/await 方式
func fetchUser() async -> String {
    // 异步操作
    return "Tom"
}

let user = await fetchUser()
print(user)
```

### async/await 的原理

1. **async 函数**：标记为 `async` 的函数可以在内部使用 `await`
2. **await**：暂停当前执行，等待异步操作完成
3. **编译器转换**：编译器会把 async/await 转换为状态机，实际上还是异步执行，但代码看起来是同步的

### 为什么要用 async/await？

| 传统回调 | async/await |
|----------|-------------|
| 嵌套回调（回调地狱） | 线性代码，易读 |
| 错误处理分散 | 统一的 try-catch |
| 状态管理复杂 | 状态清晰 |
| 难以调试 | 堆栈清晰 |

---

## 启动和使用

### 环境要求

- Swift 5.5+
- macOS 或 Linux

### 安装和运行

```bash
cd swift-async-await-demo
swift run
```

---

## 教程

### 基本 async/await

定义异步函数：

```swift
func fetchUser() async -> String {
    // 模拟异步操作
    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5秒
    return "Tom"
}

func fetchUserProfile() async -> String {
    try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3秒
    return "Profile: Tom, 25 years old"
}
```

调用异步函数：

```swift
// 顺序执行
func loadData() async {
    print("开始加载...")
    let user = await fetchUser()      // 等待完成
    print("用户: \(user)")
    let profile = await fetchUserProfile()  // 再等待
    print("资料: \(profile)")
}

Task {
    await loadData()
}
```

**注意**：顺序执行总时间是 0.5s + 0.3s = 0.8s

### 并发执行：async let

如果多个异步操作**没有依赖关系**，可以并行执行：

```swift
func fetchFriends() async -> [String] {
    try? await Task.sleep(nanoseconds: 500_000_000)
    return ["Alice", "Bob", "Charlie"]
}

func fetchPosts() async -> [String] {
    try? await Task.sleep(nanoseconds: 300_000_000)
    return ["Post 1", "Post 2", "Post 3"]
}

func loadSocialData() async {
    print("开始加载社交数据...")

    // 并发执行两个异步操作
    async let friends = fetchFriends()
    async let posts = fetchPosts()

    // 等待两者都完成
    let (f, p) = await (friends, posts)
    print("朋友: \(f)")
    print("帖子: \(p)")
}

Task {
    await loadSocialData()
}
```

**注意**：并发执行总时间是 max(0.5s, 0.3s) = 0.5s

### Task：创建异步任务

`Task` 是 Swift 并发中的核心概念，用于创建异步任务：

```swift
// 创建并立即运行
Task {
    let result = await someAsyncFunction()
    print(result)
}

// 创建可取消的任务
let task = Task {
    try? await fetchData()
}

// 取消任务
task.cancel()
```

### Task 取消

异步函数可以通过 `Task.isCancelled` 检查是否被取消：

```swift
func fetchData() async throws -> String {
    for i in 1...5 {
        try await Task.sleep(nanoseconds: 200_000_000)
        if Task.isCancelled {
            throw CancellationError()
        }
        print("加载中... \(i)")
    }
    return "完成"
}

// 使用
Task {
    let task = Task {
        try? await fetchData()
    }

    try? await Task.sleep(nanoseconds: 600_000_000)
    task.cancel()  // 取消任务
}
```

### 错误处理：throws 和 async

async 函数可以同时使用 throws：

```swift
enum NetworkError: Error {
    case notFound
    case serverError
}

func fetchSecureData() async throws -> String {
    try await Task.sleep(nanoseconds: 200_000_000)
    throw NetworkError.notFound
}

// 使用 do-catch
Task {
    do {
        let data = try await fetchSecureData()
        print("数据: \(data)")
    } catch NetworkError.notFound {
        print("404 未找到")
    } catch {
        print("错误: \(error)")
    }

    // 使用 try?
    let result = try? await fetchSecureData()
    print("可选结果: \(result ?? "nil")")
}
```

### TaskGroup：动态并发

`TaskGroup` 用于处理数量不确定的并发任务：

```swift
func fetchUrls(_ urls: [String]) async -> [String] {
    await withTaskGroup(of: String.self) { group in
        // 为每个 URL 创建任务
        for url in urls {
            group.addTask {
                try? await Task.sleep(nanoseconds: 100_000_000)
                return "Response from \(url)"
            }
        }

        // 收集所有结果
        var results: [String] = []
        for await result in group {
            results.append(result)
        }
        return results
    }
}

Task {
    let urls = ["url1", "url2", "url3"]
    let responses = await fetchUrls(urls)
    print("响应: \(responses)")
}
```

---

## 关键代码详解

### async let 的原理

```swift
async let friends = fetchFriends()
async let posts = fetchPosts()
let (f, p) = await (friends, posts)
```

`async let` 的工作原理：
1. 立即启动 `fetchFriends()` 和 `fetchPosts()`（不阻塞）
2. 创建两个"未解决的"协程
3. 当执行到 `await` 时，等待所有任务完成

### withTaskGroup 的原理

```swift
await withTaskGroup(of: String.self) { group in
    group.addTask { ... }
}
```

- `withTaskGroup` 创建一个任务组
- `addTask` 动态添加并发任务
- `for await` 收集结果
- 任务组会自动等待所有子任务完成

---

## 总结

async/await 是 Swift 并发编程的核心：

1. **简洁易读** — 异步代码像同步一样写
2. **并发执行** — 用 `async let` 和 `TaskGroup` 提高性能
3. **错误处理** — 和同步代码统一的 try-catch
4. **Task 取消** — 支持优雅的任务取消

掌握 async/await 是现代 Swift 开发的必备技能。
