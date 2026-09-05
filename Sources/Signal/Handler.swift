#if compiler(>=6.0)
public import LibC
#else
import LibC
#endif

public enum Handler: Equatable {
    case `default`
    case ignore
    case posix(@convention(c) (
        _ signal: CInt,
        _ info: UnsafeMutablePointer<siginfo_t>?,
        _ context: UnsafeMutableRawPointer?
    ) -> Void)
    case ansiC(@convention(c) (_ signal: CInt) -> Void)
    
    var pointer: OpaquePointer? {
        let address: Int
        switch self {
        case .default:
            address = unsafeBitCast(SIG_DFL, to: Int.self)
            
        case .ignore:
            address = unsafeBitCast(SIG_IGN, to: Int.self)
            
        case .posix(let handler):
            address = unsafeBitCast(handler, to: Int.self)
            
        case .ansiC(let handler):
            address = unsafeBitCast(handler, to: Int.self)
        }
        return OpaquePointer(bitPattern: address)
    }
}

extension Handler: Sendable {}

public extension Handler {
    static func ==(lhs: Handler, rhs: Handler) -> Bool {
        switch (lhs, rhs) {
        case (.default, .default), (.ignore, .ignore):
            return true
            
        case (.posix, .posix), (.ansiC, .ansiC):
            return lhs.pointer == rhs.pointer
            
        case (.default, _), (.ignore, _), (.posix, _), (.ansiC, _):
            return false
        }
    }
}
