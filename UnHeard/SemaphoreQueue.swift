//
//  SemaphoreQueue.swift
//  UnHeard
//
//  Created by Avya Rathod on 07/04/24.
//
import Foundation

class SafeQueue<T> {
    private var queue: [T] = []
    private let accessQueue = DispatchQueue(label: "safeQueue", attributes: .concurrent)
    
    func enqueue(_ element: T) {
        accessQueue.async(flags: .barrier) {
            print("added a frame")
            self.queue.append(element)
        }
    }
    
    func dequeue() -> T? {
        var element: T?
        accessQueue.sync {
            guard !self.queue.isEmpty else { return }
            element = self.queue.removeFirst()
            print("removed a frame")
        }
        return element
    }
    
    var isEmpty: Bool {
        var empty = true
        accessQueue.sync {
            empty = self.queue.isEmpty
        }
        return empty
    }
}
