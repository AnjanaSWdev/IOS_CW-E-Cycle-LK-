//
//  ListingDrafts.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import Foundation

extension ItemCategory {
    // Devices that may still hold the owner's accounts, photos or messages.
    var storesPersonalData: Bool {
        switch self {
        case .mobilePhones, .laptops, .cameras, .televisions: return true
        case .batteries, .monitors, .printers, .accessories: return false
        }
    }
}

// MARK: - New listing

struct ListingDraft: Equatable {
    static let maxPriceLKR = 1_000_000

    var sourceItemID: UUID?
    var title = ""
    var category: ItemCategory = .mobilePhones
    var condition: ListingCondition = .working
    var description = ""
    var mode: ListingMode = .giveaway
    var priceText = ""
    var district = ""
    var handoverNote = ""
    var confirmsDataRemoved = false
    var confirmsBatterySafe = false
    var confirmsOwnership = false

    enum Problem: Equatable {
        case noItem, titleTooShort, descriptionTooShort, noPrice, priceTooHigh, noDistrict
        case hazardousBattery, dataNotRemoved, batteryNotChecked, ownershipNotConfirmed

        var message: String {
            switch self {
            case .noItem: return "Choose the item you want to offer."
            case .titleTooShort: return "Give the listing a title (at least 3 letters)."
            case .descriptionTooShort: return "Describe what works and what doesn\u{2019}t (at least 15 characters)."
            case .noPrice: return "Enter a price, or switch to Give away."
            case .priceTooHigh: return "That price is too high. The limit is Rs. 1,000,000."
            case .noDistrict: return "Choose the district where it can be collected."
            case .hazardousBattery: return "Damaged or dead batteries can\u{2019}t be listed. Take them to a collection point instead."
            case .dataNotRemoved: return "Confirm you have signed out and erased your personal data."
            case .batteryNotChecked: return "Confirm the battery is not swollen, leaking or overheating."
            case .ownershipNotConfirmed: return "Confirm the item is yours to pass on."
            }
        }
    }

    var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedDescription: String { description.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedHandoverNote: String { handoverNote.trimmingCharacters(in: .whitespacesAndNewlines) }

    var priceLKR: Int {
        mode == .giveaway ? 0 : (Int(priceText.filter(\.isNumber)) ?? 0)
    }

    var requiresDataConfirmation: Bool { category.storesPersonalData }

    func problems() -> [Problem] {
        var found: [Problem] = []
        if sourceItemID == nil { found.append(.noItem) }
        if category == .batteries && condition != .working { found.append(.hazardousBattery) }
        if trimmedTitle.count < 3 { found.append(.titleTooShort) }
        if trimmedDescription.count < 15 { found.append(.descriptionTooShort) }
        if mode == .sale {
            if priceLKR <= 0 { found.append(.noPrice) }
            if priceLKR > ListingDraft.maxPriceLKR { found.append(.priceTooHigh) }
        }
        if district.isEmpty { found.append(.noDistrict) }
        if requiresDataConfirmation && !confirmsDataRemoved { found.append(.dataNotRemoved) }
        if !confirmsBatterySafe { found.append(.batteryNotChecked) }
        if !confirmsOwnership { found.append(.ownershipNotConfirmed) }
        return found
    }

    var firstProblem: Problem? { problems().first }

    // Fills the form from an item in My items.
    mutating func apply(_ item: ItemRecord) {
        sourceItemID = item.id
        title = item.name
        category = item.category
        condition = ListingCondition.suggested(for: item.condition)
        if trimmedDescription.isEmpty { description = item.notes }
    }
}

// MARK: - New request

struct RequestDraft: Equatable {
    static let maxMessageLength = 300

    var purpose: RequestPurpose = .useIt
    var message = ""
    var phone = ""

    enum Problem: Equatable {
        case messageTooShort, messageTooLong, invalidPhone

        var message: String {
            switch self {
            case .messageTooShort: return "Tell the owner a little about why you would like it (at least 10 characters)."
            case .messageTooLong: return "Keep your message under 300 characters."
            case .invalidPhone: return "Enter a phone number the owner can call, for example 077 123 4567."
            }
        }
    }

    var trimmedMessage: String { message.trimmingCharacters(in: .whitespacesAndNewlines) }

    func problems() -> [Problem] {
        var found: [Problem] = []
        if trimmedMessage.count < 10 { found.append(.messageTooShort) }
        if trimmedMessage.count > RequestDraft.maxMessageLength { found.append(.messageTooLong) }
        if RequestDraft.normalizedPhone(phone) == nil { found.append(.invalidPhone) }
        return found
    }

    var firstProblem: Problem? { problems().first }

    // Digits with an optional leading "+". Nil when it does not look like a phone number.
    static func normalizedPhone(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = trimmed.filter(\.isNumber)
        guard (9...12).contains(digits.count) else { return nil }
        let allowed = Set("0123456789 -()+")
        guard trimmed.allSatisfy({ allowed.contains($0) }) else { return nil }
        return (trimmed.hasPrefix("+") ? "+" : "") + digits
    }
}
