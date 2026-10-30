//
//  CommunityModel.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import Foundation


enum ListingMode: String, CaseIterable, Identifiable {
    case giveaway, sale
    var id: String { rawValue }
    var displayName: String { self == .giveaway ? "Give away" : "Sell" }
}

// Honest condition labels, the way second-hand platforms use them ("for parts or not working").
enum ListingCondition: String, CaseIterable, Identifiable {
    case working, needsRepair, forParts
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .working: return "Works"
        case .needsRepair: return "Needs repair"
        case .forParts: return "For parts"
        }
    }

    var detail: String {
        switch self {
        case .working: return "Everything works as it should."
        case .needsRepair: return "Has a fault someone could fix, such as a cracked screen or a tired battery."
        case .forParts: return "Does not work. Useful for spare parts only."
        }
    }

    /// Starting point taken from the condition saved in My items.
    static func suggested(for condition: ItemCondition) -> ListingCondition {
        switch condition {
        case .working: return .working
        case .damaged: return .needsRepair
        case .notWorking: return .forParts
        }
    }
}

enum ListingStatus: String {
    case open, reserved, completed, withdrawn, expired

    var displayName: String {
        switch self {
        case .open: return "Open"
        case .reserved: return "Reserved"
        case .completed: return "Handed over"
        case .withdrawn: return "Withdrawn"
        case .expired: return "Expired"
        }
    }
}

enum RequestStatus: String {
    case pending, accepted, declined, withdrawn, completed, cancelled

    var displayName: String {
        switch self {
        case .pending: return "Waiting for the owner"
        case .accepted: return "Accepted"
        case .declined: return "Not chosen"
        case .withdrawn: return "You withdrew"
        case .completed: return "Handed over"
        case .cancelled: return "Cancelled by owner"
        }
    }
}


enum RequestPurpose: String, CaseIterable, Identifiable {
    case useIt, repairIt, forParts, communityProject
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .useIt: return "I will use it"
        case .repairIt: return "I will repair it"
        case .forParts: return "I need it for parts"
        case .communityProject: return "School or community project"
        }
    }
}

enum SriLankaDistricts {
    static let all = [
        "Ampara", "Anuradhapura", "Badulla", "Batticaloa", "Colombo", "Galle", "Gampaha", "Hambantota",
        "Jaffna", "Kalutara", "Kandy", "Kegalle", "Kilinochchi", "Kurunegala", "Mannar", "Matale",
        "Matara", "Monaragala", "Mullaitivu", "Nuwara Eliya", "Polonnaruwa", "Puttalam", "Ratnapura",
        "Trincomalee", "Vavuniya"
    ]
}

// MARK: - Listing

struct Listing: Identifiable, Equatable {
    static let lifetimeDays = 14
    static let recyclingNudgeAfterDays = 7
    static let maxRequests = 15

    let id: String
    var ownerUID: String
    var ownerName: String
    /// UUID string of the Core Data item. Only the owner's phone can use it.
    var sourceItemID: String?
    var title: String
    var category: ItemCategory
    var condition: ListingCondition
    var description: String
    var mode: ListingMode
    var priceLKR: Int
    var district: String
    var handoverNote: String
    var status: ListingStatus
    /// Total requests received (never goes down).
    var requestCount: Int
    var createdAt: Date
    var expiresAt: Date
    var reservedForUID: String?
    var reservedForName: String?

    init(id: String,
         ownerUID: String,
         ownerName: String = "",
         sourceItemID: String? = nil,
         title: String,
         category: ItemCategory = .accessories,
         condition: ListingCondition = .working,
         description: String = "",
         mode: ListingMode = .giveaway,
         priceLKR: Int = 0,
         district: String = "",
         handoverNote: String = "",
         status: ListingStatus = .open,
         requestCount: Int = 0,
         createdAt: Date = Date(),
         expiresAt: Date? = nil,
         reservedForUID: String? = nil,
         reservedForName: String? = nil) {
        self.id = id
        self.ownerUID = ownerUID
        self.ownerName = ownerName
        self.sourceItemID = sourceItemID
        self.title = title
        self.category = category
        self.condition = condition
        self.description = description
        self.mode = mode
        self.priceLKR = priceLKR
        self.district = district
        self.handoverNote = handoverNote
        self.status = status
        self.requestCount = requestCount
        self.createdAt = createdAt
        self.expiresAt = expiresAt ?? createdAt.addingTimeInterval(Double(Listing.lifetimeDays) * 86_400)
        self.reservedForUID = reservedForUID
        self.reservedForName = reservedForName
    }

    var priceText: String {
        mode == .giveaway || priceLKR == 0 ? "Free" : "Rs. \(priceLKR.formatted())"
    }

    /// Open listings stop being offered after 14 days.
    func isExpired(now: Date) -> Bool {
        status == .open && expiresAt <= now
    }

    func isInFeed(now: Date) -> Bool {
        status == .open && !isExpired(now: now)
    }

    func daysLeft(now: Date) -> Int {
        max(0, Int((expiresAt.timeIntervalSince(now) / 86_400).rounded(.up)))
    }

    func ageInDays(now: Date) -> Int {
        max(0, Int(now.timeIntervalSince(createdAt) / 86_400))
    }

    // After a week with no requests we suggest the responsible fallback: recycle it.
    func shouldSuggestRecycling(now: Date) -> Bool {
        status == .open && requestCount == 0 && ageInDays(now: now) >= Listing.recyclingNudgeAfterDays
    }

    func requestBlock(for uid: String, hasExistingRequest: Bool, now: Date) -> RequestBlock? {
        if ownerUID == uid { return .ownListing }
        if status != .open { return .notOpen }
        if isExpired(now: now) { return .expired }
        if hasExistingRequest { return .alreadyRequested }
        if requestCount >= Listing.maxRequests { return .full }
        return nil
    }
}

// Reasons a person cannot request a listing.
enum RequestBlock: Equatable {
    case ownListing, notOpen, expired, alreadyRequested, full

    var message: String {
        switch self {
        case .ownListing: return "This is your own listing."
        case .notOpen: return "This item has already been reserved or is no longer available."
        case .expired: return "This listing has expired."
        case .alreadyRequested: return "You have already sent a request for this item."
        case .full: return "This item has received the maximum number of requests."
        }
    }
}

// MARK: - Request

struct ListingRequest: Identifiable, Equatable {
    /// "<listingID>_<requesterUID>": one request per person per listing, enforced by the ID itself.
    let id: String
    var listingID: String
    var listingTitle: String
    var ownerUID: String
    var requesterUID: String
    var requesterName: String
    var purpose: RequestPurpose
    var message: String
    var contactPhone: String
    var status: RequestStatus
    
    /// Filled in by the owner when they accept. Only the owner and this requester can read it.
    var ownerContact: String
    var createdAt: Date

    static func makeID(listingID: String, requesterUID: String) -> String {
        "\(listingID)_\(requesterUID)"
    }
}



extension AuthUser {
    // What other users see: first name and last initial ("Anjana P."). Never the email.
    var publicName: String {
        let parts = name.split(separator: " ")
        guard let first = parts.first else { return "Community member" }
        guard parts.count > 1, let initial = parts.last?.first else { return String(first) }
        return "\(first) \(initial)."
    }
}
