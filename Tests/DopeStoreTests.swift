import XCTest
@testable import DopeStore

final class DopeStoreTests: XCTestCase {
    func testPairingRecordValidatorAcceptsRecognizableRecord() throws {
        let plist: [String: Any] = [
            "HostID": "test-host-id",
            "DeviceCertificate": Data([0x01, 0x02]),
            "HostCertificate": Data([0x03, 0x04]),
            "SystemBUID": "test-system-buid"
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
        let result = try PairingRecordValidator.validate(data)
        XCTAssertEqual(result.hostIdentifier, "test-host-id")
        XCTAssertEqual(result.byteCount, data.count)
    }

    func testPairingRecordValidatorRejectsNonPropertyList() {
        XCTAssertThrowsError(try PairingRecordValidator.validate(Data("not a plist".utf8)))
    }

    func testPairingRecordValidatorRejectsRecordWithoutIdentity() throws {
        let plist: [String: Any] = ["HostCertificate": Data([0x01])]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        XCTAssertThrowsError(try PairingRecordValidator.validate(data))
    }

    func testExpirationPolicyStates() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertEqual(ExpirationPolicy.status(for: now.addingTimeInterval(10_000), now: now), .valid)
        XCTAssertEqual(ExpirationPolicy.status(for: now.addingTimeInterval(1_000), now: now), .expiringSoon)
        XCTAssertEqual(ExpirationPolicy.status(for: now.addingTimeInterval(-1), now: now), .expired)
    }
}
