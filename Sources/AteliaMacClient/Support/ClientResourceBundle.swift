import Foundation

enum ClientResourceBundle {
    static let thirdPartyNoticesResourceName = "THIRD_PARTY_NOTICES"
    static let thirdPartyNoticesFileExtension = "md"

    static func thirdPartyNoticesURL(in bundle: Bundle = .module) -> URL? {
        bundle.url(
            forResource: thirdPartyNoticesResourceName,
            withExtension: thirdPartyNoticesFileExtension
        )
    }
}
