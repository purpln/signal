#if compiler(>=6.0)
public import LibC
#else
import LibC
#endif

public struct Signal: RawRepresentable, Equatable, Hashable {
    public let rawValue: CInt
    
    public init(rawValue: CInt) {
        self.rawValue = rawValue
    }
}

public extension Signal {
    @inlinable
    static var hangup: Signal { Signal(rawValue: SIGHUP) }
    
    @inlinable
    static var interrupt: Signal { Signal(rawValue: SIGINT) }
    
    @inlinable
    static var quit: Signal { Signal(rawValue: SIGQUIT) }
    
    @inlinable
    static var illegal: Signal { Signal(rawValue: SIGILL) }
    
    @inlinable
    static var trap: Signal { Signal(rawValue: SIGTRAP) }
    
    @inlinable
    static var abort: Signal { Signal(rawValue: SIGABRT) }
    
    @inlinable
    static var arithmetic: Signal { Signal(rawValue: SIGFPE) }
    
    @inlinable
    static var segmentation: Signal { Signal(rawValue: SIGSEGV) }
    
    @inlinable
    static var kill: Signal { Signal(rawValue: SIGKILL) }
    
    @inlinable
    static var bus: Signal { Signal(rawValue: SIGBUS) }
    
    @inlinable
    static var iot: Signal { Signal(rawValue: SIGIOT) }
    
    @inlinable
    static var sys: Signal { Signal(rawValue: SIGSYS) }
    
    @inlinable
    static var pipe: Signal { Signal(rawValue: SIGPIPE) }
    
    @inlinable
    static var alarm: Signal { Signal(rawValue: SIGALRM) }
    
    @inlinable
    static var terminate: Signal { Signal(rawValue: SIGTERM) }
    
    @inlinable
    static var urgent: Signal { Signal(rawValue: SIGURG) }
    
    @inlinable
    static var stop: Signal { Signal(rawValue: SIGSTOP) }
    
    @inlinable
    static var `continue`: Signal { Signal(rawValue: SIGCONT) }
    
    @inlinable
    static var child: Signal { Signal(rawValue: SIGCHLD) }
    
    @inlinable
    static var window: Signal { Signal(rawValue: SIGWINCH) }
    
#if canImport(Darwin)
    @inlinable
    static var info: Signal { Signal(rawValue: SIGINFO) }
    
#elseif canImport(Glibc) || canImport(Musl) || canImport(Android)
    @inlinable
    static var poll: Signal { Signal(rawValue: SIGPOLL) }
#endif
    @inlinable
    static var io: Signal { Signal(rawValue: SIGIO) }
    
    @inlinable
    static var usr1: Signal { Signal(rawValue: SIGUSR1) }
    
    @inlinable
    static var usr2: Signal { Signal(rawValue: SIGUSR2) }
}

extension Signal: CustomStringConvertible {
    public var description: String {
        "\(name ?? "\(rawValue)") - \(about ?? "unknown")"
    }
}

public extension Signal {
#if canImport(Darwin)
    var name: String? {
        guard rawValue >= 0 && rawValue < NSIG else { return nil }
        
        return withUnsafePointer(to: sys_signame, { pointer in
            pointer.withMemoryRebound(to: UnsafePointer<UInt8>?.self, capacity: Int(NSIG), { pointer in
                pointer.advanced(by: Int(rawValue)).pointee.flatMap(String.init)
            })
        })
    }
    
    var about: String? {
        guard rawValue >= 0 && rawValue < NSIG else { return nil }
        
        return withUnsafePointer(to: sys_siglist, { pointer in
            pointer.withMemoryRebound(to: UnsafePointer<UInt8>?.self, capacity: Int(NSIG), { pointer in
                pointer.advanced(by: Int(rawValue)).pointee.flatMap(String.init)
            })
        })
    }
#elseif canImport(Glibc) || canImport(Musl)
    var name: String? {
        return nil
    }
    
    var about: String? {
        guard let cstr = strsignal(rawValue) else { return nil }
        return String(cString: cstr)
    }
#elseif canImport(Android)
    var name: String? {
        return nil
    }
    
    var about: String? {
        let cstr = strsignal(rawValue)
        return String(cString: cstr)
    }
#endif
}


extension Signal: CaseIterable {
    public static var allCases: [Signal] {
        (1..<NSIG).map(Signal.init)
    }
}

extension Signal: Sendable {}

public extension Signal {
    static func set(from sigset: sigset_t) -> Set<Signal> {
        withUnsafePointer(to: sigset, { pointer in
            Set((1..<NSIG).filter({ sigismember(pointer, $0) != 0 }).map(Signal.init))
        })
    }
    
    static func sigset(from signals: Set<Signal>) -> sigset_t {
        var sigset = sigset_t()
        sigemptyset(&sigset)
        for signal in signals {
            sigaddset(&sigset, signal.rawValue)
        }
        return sigset
    }
    
    var sigset: sigset_t {
        var sigset = sigset_t()
        sigemptyset(&sigset)
        sigaddset(&sigset, rawValue)
        return sigset
    }
}

public extension Set where Element == Signal {
    static var killing: Set<Signal> {
        [.terminate, .interrupt, .quit, .hangup]
    }
}
