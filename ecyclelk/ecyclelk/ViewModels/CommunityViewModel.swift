//
//  CommunityViewModel.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import Foundation
import Observation

/// Drives the Community feature: browsing, listing your own items, requesting, accepting and handing over.
@MainActor
@Observable
final class CommunityViewModel {

    enum Section: String, CaseIterable, Identifiable {
        case browse = "Browse"
        case mine = "My listings"
        case requests = "My requests"
        var id: String { rawValue }
    }

    private(set) var feed: [Listing] = []
    private(set) var myListings: [Listing] = []
    private(set) var myRequests: [ListingRequest] = []
    private(set) var requestsByListing: [String: [ListingRequest]] = [:]
    private(set) var availableItems: [ItemRecord] = []
    private(set) var isLoading = false

    var errorMessage: String?
    var noticeMessage: String?
    var section: Section = .browse
    var searchText = ""
    var categoryFilter: ItemCategory?
    var modeFilter: ListingMode?
    /// Empty string means every district.
    var districtFilter = ""

    let user: AuthUser
    private let service: CommunityServiceProtocol
    private let items: any ItemsStore
    private let now: () -> Date

    init(service: CommunityServiceProtocol,
         items: any ItemsStore,
         user: AuthUser,
         now: @escaping () -> Date = { Date() }) {
        self.service = service
        self.items = items
        self.user = user
        self.now = now
    }

    var currentDate: Date { now() }

    // MARK: - Loading

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let mine = try await service.fetchListings(ownerUID: user.uid)
            myListings = await closeExpired(in: mine).sorted { $0.createdAt > $1.createdAt }
            feed = try await service.fetchOpenListings()
            myRequests = try await service.fetchRequests(byRequester: user.uid).sorted { $0.createdAt > $1.createdAt }
            loadAvailableItems()
            errorMessage = nil
        } catch {
            errorMessage = describe(error)
        }
    }

    /// Items that can still be offered: saved, not planned for recycling and not already listed.
    func loadAvailableItems() {
        availableItems = ((try? items.fetchItems(ownerUID: user.uid)) ?? []).filter { $0.status == .saved }
    }

    func loadRequests(for listing: Listing) async {
        do {
            let loaded = try await service.fetchRequests(forListing: listing.id, ownerUID: user.uid)
            requestsByListing[listing.id] = loaded.sorted { $0.createdAt < $1.createdAt }
        } catch {
            errorMessage = describe(error)
        }
    }

    /// The owner's open listings that ran past 14 days are closed, and the item goes back to "saved".
    private func closeExpired(in listings: [Listing]) async -> [Listing] {
        var result: [Listing] = []
        for var listing in listings {
            if listing.isExpired(now: now()) {
                do {
                    try await service.close(listing, as: .expired)
                    listing.status = .expired
                    returnItemToSaved(of: listing)
                } catch {
                    errorMessage = describe(error)
                }
            }
            result.append(listing)
        }
        return result
    }

    // MARK: - Reading

    func listing(withID id: String) -> Listing? {
        myListings.first { $0.id == id } ?? feed.first { $0.id == id }
    }

    func existingRequest(for listingID: String) -> ListingRequest? {
        myRequests.first { $0.listingID == listingID }
    }

    var visibleFeed: [Listing] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return feed
            .filter { listing in
                guard listing.isInFeed(now: now()), listing.ownerUID != user.uid else { return false }
                if let categoryFilter, listing.category != categoryFilter { return false }
                if let modeFilter, listing.mode != modeFilter { return false }
                if !districtFilter.isEmpty, listing.district != districtFilter { return false }
                if !query.isEmpty {
                    let haystack = [listing.title, listing.description, listing.district].joined(separator: " ")
                    if !haystack.localizedCaseInsensitiveContains(query) { return false }
                }
                return true
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var hasActiveFilters: Bool {
        categoryFilter != nil || modeFilter != nil || !districtFilter.isEmpty || !searchText.isEmpty
    }

    func clearFilters() {
        categoryFilter = nil
        modeFilter = nil
        districtFilter = ""
        searchText = ""
    }

    var pendingRequestsOnMyListings: Int {
        requestsByListing.values.joined().filter { $0.status == .pending }.count
    }

    // MARK: - Listing actions (owner)

    func createListing(_ draft: ListingDraft) async -> Bool {
        if let problem = draft.firstProblem {
            errorMessage = problem.message
            return false
        }
        return await perform {
            let listing = try await service.createListing(draft, owner: user, now: now())
            myListings.insert(listing, at: 0)
            if let itemID = draft.sourceItemID {
                try? items.setStatus(.listed, forItemWithID: itemID, on: now())
            }
            loadAvailableItems()
            section = .mine
            noticeMessage = "Your item is now listed for \(Listing.lifetimeDays) days."
        }
    }

    func accept(_ request: ListingRequest, in listing: Listing, ownerContact: String) async -> Bool {
        guard listing.ownerUID == user.uid else { return false }
        guard listing.status == .open else {
            errorMessage = CommunityError.listingChanged.errorDescription
            return false
        }
        guard let phone = RequestDraft.normalizedPhone(ownerContact) else {
            errorMessage = RequestDraft.Problem.invalidPhone.message
            return false
        }
        return await perform {
            try await service.accept(request, in: listing, ownerContact: phone)
            update(listing.id) {
                $0.status = .reserved
                $0.reservedForUID = request.requesterUID
                $0.reservedForName = request.requesterName
            }
            requestsByListing[listing.id] = (requestsByListing[listing.id] ?? []).map { other in
                var copy = other
                if other.id == request.id {
                    copy.status = .accepted
                    copy.ownerContact = phone
                } else if other.status == .pending {
                    copy.status = .declined
                }
                return copy
            }
            noticeMessage = "Accepted. \(request.requesterName) can now see your number. Agree a time and place to meet."
        }
    }

    func decline(_ request: ListingRequest) async -> Bool {
        await perform {
            try await service.decline(request)
            setRequestStatus(request, to: .declined)
        }
    }

    /// The item was handed over: the listing closes and the item counts as given a second life.
    func markHandedOver(_ listing: Listing) async -> Bool {
        guard listing.ownerUID == user.uid, listing.status == .reserved else { return false }
        return await perform {
            try await service.complete(listing)
            update(listing.id) { $0.status = .completed }
            if let itemID = itemID(of: listing) {
                try? items.setStatus(.rehomed, forItemWithID: itemID, on: now())
            }
            loadAvailableItems()
            noticeMessage = "Well done. That item has been given a second life."
        }
    }

    /// Nobody turned up: the listing goes back to open and the requester is released.
    func reopen(_ listing: Listing) async -> Bool {
        guard listing.ownerUID == user.uid, listing.status == .reserved else { return false }
        return await perform {
            try await service.reopen(listing)
            update(listing.id) {
                $0.status = .open
                $0.reservedForUID = nil
                $0.reservedForName = nil
            }
            await loadRequests(for: listing)
        }
    }

    /// Takes the listing down. The item goes back to "saved" so it can be recycled instead.
    func withdraw(_ listing: Listing) async -> Bool {
        guard listing.ownerUID == user.uid, listing.status == .open || listing.status == .reserved else { return false }
        return await perform {
            try await service.close(listing, as: .withdrawn)
            update(listing.id) { $0.status = .withdrawn }
            returnItemToSaved(of: listing)
            loadAvailableItems()
        }
    }

    // MARK: - Request actions (requester)

    func submitRequest(_ draft: RequestDraft, for listing: Listing) async -> Bool {
        if let block = listing.requestBlock(for: user.uid,
                                            hasExistingRequest: existingRequest(for: listing.id) != nil,
                                            now: now()) {
            errorMessage = block.message
            return false
        }
        if let problem = draft.firstProblem {
            errorMessage = problem.message
            return false
        }
        return await perform {
            let request = try await service.submitRequest(draft, for: listing, requester: user, now: now())
            myRequests.insert(request, at: 0)
            if let index = feed.firstIndex(where: { $0.id == listing.id }) {
                feed[index].requestCount += 1
            }
            noticeMessage = "Request sent. The owner chooses who gets the item."
        }
    }

    func withdrawRequest(_ request: ListingRequest) async -> Bool {
        guard request.requesterUID == user.uid, request.status == .pending else { return false }
        return await perform {
            try await service.withdrawRequest(request)
            if let index = myRequests.firstIndex(where: { $0.id == request.id }) {
                myRequests[index].status = .withdrawn
            }
        }
    }

    func report(_ listing: Listing, reason: String) async {
        _ = await perform {
            try await service.report(listing, reason: reason, reporter: user)
            noticeMessage = "Thanks. We will review this listing."
        }
    }

    // MARK: - Helpers

    private func perform(_ work: () async throws -> Void) async -> Bool {
        do {
            errorMessage = nil
            try await work()
            return true
        } catch {
            errorMessage = describe(error)
            return false
        }
    }

    private func describe(_ error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    private func update(_ listingID: String, _ change: (inout Listing) -> Void) {
        if let index = myListings.firstIndex(where: { $0.id == listingID }) { change(&myListings[index]) }
        if let index = feed.firstIndex(where: { $0.id == listingID }) { change(&feed[index]) }
    }

    private func setRequestStatus(_ request: ListingRequest, to status: RequestStatus) {
        guard var list = requestsByListing[request.listingID],
              let index = list.firstIndex(where: { $0.id == request.id }) else { return }
        list[index].status = status
        requestsByListing[request.listingID] = list
    }

    private func itemID(of listing: Listing) -> UUID? {
        listing.sourceItemID.flatMap { UUID(uuidString: $0) }
    }

    private func returnItemToSaved(of listing: Listing) {
        if let itemID = itemID(of: listing) {
            try? items.setStatus(.saved, forItemWithID: itemID, on: now())
        }
    }
}
