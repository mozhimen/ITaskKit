//
//  ThreadSafePublished.swift
//  SUtilKit.SwiftUI
//
//  Created by Taiyou on 2025/8/28.
//

// 使用示例
//class ThreadSafeViewModel: ObservableObject {
//    @ThreadSafePublished var counter = 0  // ✅ 线程安全
//    
//    func concurrentIncrement() {
//        DispatchQueue.concurrentPerform(iterations: 100) { _ in
//            _counter.wrappedValue += 1  // ✅ 安全：有锁保护
//        }
//    }
//}
import Foundation
@preconcurrency import Combine

@propertyWrapper
public struct ThreadSafePublished<Value:Sendable>: Sendable {
    private let lock = NSLock()
    private var _value: Value
    private let subjectHolder: SubjectHolder<Value>  // 使用类来持有 subject
    
    public var wrappedValue: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            _value = newValue
            lock.unlock()
            
            // 通过持有者类发送，避免捕获 self
            subjectHolder.send(newValue)
        }
    }
    
    public var projectedValue: AnyPublisher<Value, Never> {
        subjectHolder.subject.eraseToAnyPublisher()
    }
    
    public init(wrappedValue: Value) {
        self._value = wrappedValue
        self.subjectHolder = SubjectHolder(value: wrappedValue)
    }
}

// 用于持有 Subject 的类
private final class SubjectHolder<Value: Sendable>: Sendable {
    let subject: CurrentValueSubject<Value, Never>
    private let queue = DispatchQueue.main  // 主队列
    
    init(value: Value) {
        self.subject = CurrentValueSubject(value)
    }
    
    func send(_ value: Value) {
        // 在主线程发送值
        if Thread.isMainThread {
            subject.send(value)
        } else {
            queue.async {
                self.subject.send(value)
            }
        }
    }
}
