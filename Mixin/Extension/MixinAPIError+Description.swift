import Foundation
import MixinServices

extension MixinAPIError {
    
    var localizedDescription: String {
        switch self {
        case .foundNilResult:
            return R.string.localizable.error_internal("\(self)")
            
        case .prerequistesNotFulfilled:
            return R.string.localizable.error_internal("\(self)")
        case .invalidJSON:
            return R.string.localizable.error_internal("\(self)")
        case let .httpTransport(error):
            if let underlying = (error.underlyingError as NSError?), underlying.domain == NSURLErrorDomain {
                switch underlying.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorCannotConnectToHost:
                    return R.string.localizable.error_no_connection()
                case NSURLErrorTimedOut:
                    return R.string.localizable.error_connection_timeout()
                case NSURLErrorNetworkConnectionLost:
                    return R.string.localizable.error_network_connection_lost()
                default:
                    return underlying.localizedDescription
                }
            } else if case .responseValidationFailed(reason: .unacceptableStatusCode) = error {
                return R.string.localizable.error_server_5xx()
            } else {
                return error.localizedDescription
            }
        case .webSocketTimeOut, .clockSkewDetected:
            return R.string.localizable.error_connection_timeout()
        case let .unknown(status, code):
            return R.string.localizable.error_two_parts("\(status)", "\(code)")
            
        case .invalidRequestBody:
            return R.string.localizable.error_invalid_request_body()
        case .unauthorized:
            return R.string.localizable.error_unauthorized()
        case .forbidden:
            return R.string.localizable.error_forbidden()
        case .notFound:
            return R.string.localizable.error_not_found()
        case .tooManyRequests:
            return R.string.localizable.error_too_many_requests()
            
        case .internalServerError, .blazeServerError, .blazeOperationTimedOut:
            return R.string.localizable.error_server_5xx()
            
        case .invalidRequestData:
            return R.string.localizable.error_invalid_request_data()
        case .failedToDeliverSMS:
            return R.string.localizable.error_failed_to_deliver_sms()
        case .invalidReCaptcha:
            return R.string.localizable.error_invalid_recaptcha()
        case .requiresReCaptcha:
            return R.string.localizable.error_requires_recaptcha()
        case .requiresUpdate:
            return R.string.localizable.app_update_short_tips()
        case .invalidPhoneNumber:
            return R.string.localizable.error_invalid_phone_number()
        case .insufficientIdentityNumber:
            return R.string.localizable.error_insufficient_identity_number()
        case .invalidInvitationCode:
            return R.string.localizable.error_invalid_invitation_code()
        case .invalidPhoneVerificationCode:
            return R.string.localizable.error_invalid_phone_verification_code()
        case .expiredPhoneVerificationCode:
            return R.string.localizable.error_expired_phone_verification_code()
        case .invalidQrCode:
            return R.string.localizable.error_invalid_qr_code()
        case .groupChatIsFull:
            return R.string.localizable.error_group_full()
        case .insufficientBalance:
            return R.string.localizable.error_insufficient_balance()
        case .malformedPin, .incorrectPin:
            return R.string.localizable.error_pin_incorrect()
        case .transferAmountTooSmall:
            return R.string.localizable.error_transfer_amount_too_small()
        case .expiredAuthorizationCode:
            return R.string.localizable.error_expired_authorization_code()
        case .phoneNumberInUse:
            return R.string.localizable.error_unavailable_phone_number()
        case .tooManyAppsCreated:
            return R.string.localizable.error_too_many_apps_created()
        case .insufficientFee:
            return R.string.localizable.error_fee_insufficient()
        case .transferIsAlreadyPaid:
            return R.string.localizable.error_transfer_is_already_paid()
        case .tooManyStickers:
            return R.string.localizable.error_too_many_stickers()
        case .withdrawAmountTooSmall:
            return R.string.localizable.error_withdrawal_amount_too_small()
        case .tooManyFriends:
            return R.string.localizable.error_too_many_friends()
        case .sendingVerificationCodeTooFrequently:
            return R.string.localizable.text_invalid_code_too_frequent()
        case .invalidEmergencyContact:
            return R.string.localizable.text_invalid_emergency_id()
        case .malformedWithdrawalMemo:
            return R.string.localizable.withdrawal_memo_format_incorrect()
        case .sharedAppReachLimit:
            return R.string.localizable.profile_shared_app_reach_limit()
        case .circleConversationReachLimit:
            return R.string.localizable.circle_conversation_add_reach_limit()
        case .invalidConversationChecksum:
            return R.string.localizable.error_invalid_conversation_checksum()
            
        case .chainNotInSync:
            return R.string.localizable.error_blockchian_not_in_sync()
        case .missingPrivateKey:
            return R.string.localizable.error_missing_private_key()
        case .malformedAddress:
            return R.string.localizable.error_malformed_address()
        case .insufficientPool:
            return R.string.localizable.error_insufficient_pool()
            
        case .invalidParameters:
            return R.string.localizable.error_invalid_parameters()
        case .invalidSDP:
            return R.string.localizable.error_invalid_sdp()
        case .invalidCandidate:
            return R.string.localizable.error_invalid_candidate()
        case .roomFull:
            return R.string.localizable.error_room_full()
        case .peerNotFound:
            return R.string.localizable.error_peer_not_found()
        case .peerClosed:
            return R.string.localizable.error_peer_closed()
        case .trackNotFound:
            return R.string.localizable.error_track_not_found()
        }
    }
    
    func localizedDescription(overridingNotFoundDescriptionWith notFoundDescription: String) -> String {
        switch self {
        case .notFound:
            return notFoundDescription
        default:
            return localizedDescription
        }
    }
    
}