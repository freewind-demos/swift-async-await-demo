// swift-async-await-demo.swift

// ============ 基本 async/await ============
func fetchUser() async -> String {
    // 模拟异步操作
    try? await Task.sleep(nanoseconds: 500_000_000)
    return "Tom"
}

func fetchUserProfile() async -> String {
    try? await Task.sleep(nanoseconds: 300_000_000)
    return "Profile: Tom, 25 years old"
}

// 顺序执行
func loadData() async {
    print("开始加载...")
    let user = await fetchUser()
    print("用户: \(user)")
    let profile = await fetchUserProfile()
    print("资料: \(profile)")
}

Task {
    await loadData()
}

// ============ 并发执行 ============
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

    async let friends = fetchFriends()
    async let posts = fetchPosts()

    let (f, p) = await (friends, posts)
    print("朋友: \(f)")
    print("帖子: \(p)")
}

Task {
    await loadSocialData()
}

// ============ Task 取消 ============
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

Task {
    let task = Task {
        try? await fetchData()
    }

    try? await Task.sleep(nanoseconds: 600_000_000)
    task.cancel()
}

// ============ try? 和 throws ============
enum NetworkError: Error {
    case notFound
    case serverError
}

func fetchSecureData() async throws -> String {
    try await Task.sleep(nanoseconds: 200_000_000)
    throw NetworkError.notFound
}

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

// ============ TaskGroup ============
func fetchUrls(_ urls: [String]) async -> [String] {
    await withTaskGroup(of: String.self) { group in
        for url in urls {
            group.addTask {
                try? await Task.sleep(nanoseconds: 100_000_000)
                return "Response from \(url)"
            }
        }

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
