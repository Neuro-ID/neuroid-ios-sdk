@propertyWrapper
struct Atomic<Value> {
    private var lock = os_unfair_lock_s()
    private var value: Value

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
        mutating get {
            os_unfair_lock_lock(&lock)
            let value = self.value
            os_unfair_lock_unlock(&lock)
            return value
        }
        set {
            os_unfair_lock_lock(&lock)
            value = newValue
            os_unfair_lock_unlock(&lock)
        }
    }
}
