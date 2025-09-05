//
//  BackgroundActor.swift
//  ITaskKit.ThreadSafe
//
//  Created by Taiyou on 2025/8/28.
//

import Foundation
// 完整的自定义背景Actor实现
@globalActor
public actor BackgroundActor {
    public static let shared = BackgroundActor()
    private let executor: any SerialExecutor
    
    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }
    
    init() {
        let queue = DispatchQueue(
            label: "com.youapp.background.actor",
            qos: .userInitiated
        )
        executor = DispatchQueueSerialExecutor(queue: queue)
    }
}

// 需要的支持类型
final class DispatchQueueSerialExecutor: SerialExecutor {
    let queue: DispatchQueue
    
    init(queue: DispatchQueue) {
        self.queue = queue
    }
    
    func enqueue(_ job: consuming ExecutorJob) {
        let unowned = UnownedJob(job)
        queue.async {
            unowned.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }
    
    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}

//// 简单的背景任务包装器
//// 简单的背景任务包装器
//enum Background {
//    @discardableResult
//    static func run<T:Sendable>(_ operation: @escaping () async throws -> T) async throws -> T {
//        try await Task.detached(operation: operation).value
//    }
//
//    @discardableResult
//    static func run<T:Sendable>(priority: TaskPriority? = nil,
//                      _ operation: @escaping () async throws -> T) async throws -> T {
//        try await Task.detached(priority: priority, operation: operation).value
//    }
//}
