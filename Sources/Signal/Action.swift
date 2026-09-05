#if compiler(>=6.0)
public import TinyFoundation
public import LibC
#else
import TinyFoundation
import LibC
#endif
import TinySystem

public struct Action: RawRepresentable, Equatable {
    public var mask: Set<Signal> = []
    public var flags: Flags = []
    
    public var handler: Handler
    
    public init(handler: Handler) {
        self.mask = []
        switch handler {
        case .posix:
            self.flags = [.info]
            
        case .ignore, .default, .ansiC:
            self.flags = []
        }
        self.handler = handler
    }
    
#if compiler(>=6.0)
    public init(signal: Signal) throws(Errno) {
        var action = sigaction()
        try nothingOrErrno(retryOnInterrupt: false, {
            sigaction(signal.rawValue, nil, &action)
        }).get()
        self.init(rawValue: action)
    }
#else
    public init(signal: Signal) throws {
        var action = sigaction()
        try nothingOrErrno(retryOnInterrupt: false, {
            sigaction(signal.rawValue, nil, &action)
        }).get()
        self.init(rawValue: action)
    }
#endif
    
    public init(rawValue: sigaction) {
        self.mask = Signal.set(from: rawValue.sa_mask)
        self.flags = Flags(rawValue: rawValue.sa_flags)
        
        let address = unsafeBitCast(rawValue.handler.handler, to: Int.self)
        switch OpaquePointer(bitPattern: address) {
        case OpaquePointer(bitPattern: unsafeBitCast(SIG_DFL, to: Int.self)):
            self.handler = .default
        case OpaquePointer(bitPattern: unsafeBitCast(SIG_IGN, to: Int.self)):
            self.handler = .ignore
        default:
            if flags.contains(.info) {
                self.handler = .posix(rawValue.handler.sigaction!)
            } else {
                self.handler = .ansiC(rawValue.handler.handler!)
            }
        }
    }
    
    public var rawValue: sigaction {
        precondition(isValid, "Handler must match the .info flag.")
        
        var ret = sigaction()
        ret.sa_mask = Signal.sigset(from: mask)
        ret.sa_flags = flags.rawValue
        
        switch handler {
        case .default:
            ret.handler.handler = SIG_DFL
            
        case .ignore:
            ret.handler.handler = SIG_IGN
            
        case .ansiC(let handler):
            ret.handler.handler = handler
            
        case .posix(let handler):
            ret.handler.sigaction = handler
        }
        return ret
    }
    
    public var isValid: Bool {
        switch handler {
        case .posix:
            return flags.contains(.info)
        case .default, .ignore, .ansiC:
            return !flags.contains(.info)
        }
    }
    
#if compiler(>=6.0)
    @discardableResult
    public func install(
        on signal: Signal,
        revertIfIgnored: Bool = true
    ) throws(Errno) -> Action? {
        var old = sigaction()
        var new = rawValue
        try nothingOrErrno(retryOnInterrupt: false, {
            sigaction(signal.rawValue, &new, &old)
        }).get()
        
        let oldSigaction = Action(rawValue: old)
        if revertIfIgnored && oldSigaction == .ignore {
            try nothingOrErrno(retryOnInterrupt: false, {
                sigaction(signal.rawValue, &old, nil)
            }).get()
            return nil
        }
        return (oldSigaction != self ? oldSigaction : nil)
    }
#else
    @discardableResult
    public func install(
        on signal: Signal,
        revertIfIgnored: Bool = true
    ) throws -> Action? {
        var old = sigaction()
        var new = rawValue
        try nothingOrErrno(retryOnInterrupt: false, {
            sigaction(signal.rawValue, &new, &old)
        }).get()
        
        let oldSigaction = Action(rawValue: old)
        if revertIfIgnored && oldSigaction == .ignore {
            try nothingOrErrno(retryOnInterrupt: false, {
                sigaction(signal.rawValue, &old, nil)
            }).get()
            return nil
        }
        return (oldSigaction != self ? oldSigaction : nil)
    }
#endif
}

extension Action: Sendable {}

public extension Action {
#if compiler(>=6.0)
    func install(
        on signals: Set<Signal>,
        revertIfIgnored: Bool = true
    ) throws(Errno) {
        var installed: [(signal: Signal, action: Action)] = []
        do throws(Errno) {
            for signal in signals.sorted(by: { $0.rawValue < $1.rawValue }) {
                guard let action = try install(
                    on: signal,
                    revertIfIgnored: revertIfIgnored
                ) else { continue }
                installed.append((signal, action))
            }
        } catch {
            for (signal, action) in installed.reversed() {
                _ = try? action.install(on: signal, revertIfIgnored: false)
            }
            throw error
        }
    }
#else
    func install(
        on signals: Set<Signal>,
        revertIfIgnored: Bool = true
    ) throws {
        var installed: [(signal: Signal, action: Action)] = []
        do {
            for signal in signals.sorted(by: { $0.rawValue < $1.rawValue }) {
                guard let action = try install(
                    on: signal,
                    revertIfIgnored: revertIfIgnored
                ) else { continue }
                installed.append((signal, action))
            }
        } catch {
            for (signal, action) in installed.reversed() {
                _ = try? action.install(on: signal, revertIfIgnored: false)
            }
            throw error
        }
    }
#endif
}

public extension Action {
    static var `default`: Action { Action(handler: .default) }
    static var ignore: Action { Action(handler: .ignore) }
}
