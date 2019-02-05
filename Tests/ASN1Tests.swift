import XCTest
import Foundation
@testable import MerchantKit

class ASN1Tests : XCTestCase {
    func testObjectIdentifierCreation() {
        let data = Data(base64Encoded: "KoZIhvcNAQcC")!
        
        let identifier = ASN1.ObjectIdentifier(bytes: data)
        
        XCTAssertEqual(identifier.stringValue, "1.2.840.113549.1.7.2")
        XCTAssertEqual(identifier.description, "[ASN1.ObjectIdentifier stringValue: 1.2.840.113549.1.7.2]")
    }
    
    func testParseEmptyData() {
        let parser = ASN1.Parser(data: Data())
        
        XCTAssertThrowsError(try parser.parse())
    }
    
    func testEmptyBufferConversion() {
        let bufferTypesNotAllowedToConvertFromEmptyBuffers: Set<ASN1.BufferType> = [.eoc, .boolean, .integer, .bitString, .octetString, .objectIdentifier, .objectDescriptor, .externalReference, .real, .enumerated, .embeddedPDV, .relativeObjectIdentifier, .sequence, .set, .numericString, .videoTextString, .utcTime, .generalizedTime, .visibleString, .generalString, .universalString, .bitmapString, .usesLongForm]
        
        for bufferType in bufferTypesNotAllowedToConvertFromEmptyBuffers {
            XCTAssertThrowsError(try ASN1.value(convertedFrom: Data(), as: bufferType)) { error in
                switch error {
                    case ASN1.PayloadValueConversionError.invalidBufferSize(foundByteCount: 0, payloadType: bufferType):
                        break
                    case let error:
                        XCTFail("unexpected error for empty buffer: \(error)")
                }
            }
        }
    }
    
    func testSuccessfulBooleanBufferConversion() {
        let trueBuffer = Data([1])
        let falseBuffer = Data([0])
        
        XCTAssertEqual(try ASN1.value(convertedFrom: trueBuffer, as: .boolean), ASN1.BufferValue.boolean(true))
        XCTAssertEqual(try ASN1.value(convertedFrom: falseBuffer, as: .boolean), ASN1.BufferValue.boolean(false))
    }
    
    func testInvalidBooleanBufferConversion() {
        let invalidBuffer = Data([0, 1])
        
        XCTAssertThrowsError(try ASN1.value(convertedFrom: invalidBuffer, as: .boolean)) { error in
            switch error {
                case ASN1.PayloadValueConversionError.invalidBufferSize(foundByteCount: 2, payloadType: .boolean):
                    break
                default:
                    XCTFail("unexpected error for invalid boolean buffer: \(error)")
            }
        }
    }
    
    func testSuccessfulStringBufferConversion() {
        let stringTypes: Set<ASN1.BufferType> = [.teletexString, .graphicString, .printableString, .utf8String, .ia5String]
        
        for bufferType in stringTypes {
            let testString = "The quick brown fox jumped over the lazy dog."
            let data = testString.data(using: .utf8)!
            
            var value: ASN1.BufferValue!
            XCTAssertNoThrow(value = try ASN1.value(convertedFrom: data, as: bufferType))
            
            XCTAssertEqual(value, .string(testString))
        }
    }
    
    func testInvalidStringBufferConversion() {
        let stringTypes: Set<ASN1.BufferType> = [.teletexString, .graphicString, .printableString, .utf8String, .ia5String]
        
        for bufferType in stringTypes {
            let invalidData = Data([0xff, 0xff])
            
            XCTAssertThrowsError(_ = try ASN1.value(convertedFrom: invalidData, as: bufferType)) { error in
                switch error {
                    case ASN1.PayloadValueConversionError.unsupportedBuffer(payloadType: bufferType):
                        break
                    case let error:
                        XCTFail("unexpected error for invalid string buffer: \(error)")
                }
            }
        }
    }
    
    func testBufferValueDescription() {
        let expectations: [(ASN1.BufferValue, String)] = [
            (.null, "null"),
            (.boolean(true), "true"),
            (.integer(123), "123"),
            (.string("test"), "'test'"),
            (.data(Data()), "0 bytes"),
            (.date("01-02-2000"), "'01-02-2000'"),
            (.objectIdentifier(ASN1.ObjectIdentifier(bytes: Data([0xFF, 0x4, 0x8, 0x16]))), "[ASN1.ObjectIdentifier stringValue: 6.15.4.8.22]")
        ]
        
        for (value, formattedDescriptionComponent) in expectations {
            let expectedDescription = "[ASN1.BufferValue value: \(formattedDescriptionComponent)]"
            
            XCTAssertEqual(String(describing: value), expectedDescription)
        }
    }
}
