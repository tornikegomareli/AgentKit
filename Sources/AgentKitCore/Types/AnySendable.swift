import Foundation

/// A type-erased `Sendable` wrapper for values that cannot be statically proven sendable.
///
/// Used internally to bridge `[String: Any]` dictionaries across concurrency boundaries.
/// Prefer typed parameters where possible — this exists for tool handler interop
/// where parameter shapes are defined at runtime by LLM tool schemas.
public struct AnySendableValue: @unchecked Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }
}

/// A sendable dictionary type used for tool parameters and custom state.
///
/// This wraps `[String: Any]` in a `Sendable`-conforming type so it can safely
/// cross actor and task boundaries. The caller is responsible for ensuring
/// the contained values are themselves safe to share across threads.
public struct SendableDictionary: @unchecked Sendable, ExpressibleByDictionaryLiteral {
    public private(set) var storage: [String: Any]

    public init(_ storage: [String: Any] = [:]) {
        self.storage = storage
    }

    public init(dictionaryLiteral elements: (String, Any)...) {
        self.storage = Dictionary(uniqueKeysWithValues: elements)
    }

    public subscript(key: String) -> Any? {
        get { storage[key] }
        set { storage[key] = newValue }
    }

    public var isEmpty: Bool { storage.isEmpty }
    public var keys: Dictionary<String, Any>.Keys { storage.keys }
}

extension SendableDictionary: CustomStringConvertible {
    public var description: String {
        storage.description
    }
}
