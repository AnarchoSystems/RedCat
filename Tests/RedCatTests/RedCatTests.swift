import XCTest

#if compiler(>=5.5) && canImport(_Concurrency)
@MainActor
final class RedCatTests: XCTestCase {}
#else
final class RedCatTests: XCTestCase {}
#endif
