//
//  CommunityService.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import Foundation

/// Everything the Community screens need from the backend. The app uses Firestore; tests use a fake.
@MainActor
protocol CommunityServiceProtocol {
    // Listings
    func fetchOpenListings() async throws -> [Listing]
    func fetchListings(ownerUID: String) async throws -> [Listing]
    func createListing(_ draft: ListingDraft, owner: AuthUser, now: Date) async throws -> Listing
    /// Withdraws or expires a listing. Pending requests are declined, an accepted one is cancelled.
    func close(_ listing: Listing, as status: ListingStatus) async throws
    /// Reserved back to open. The accepted request is cancelled.
    func reopen(_ listing: Listing) async throws
    /// Reserved to completed (the item was handed over).
    func complete(_ listing: Listing) async throws

    // Requests
    func fetchRequests(forListing listingID: String, ownerUID: String) async throws -> [ListingRequest]
    func fetchRequests(byRequester uid: String) async throws -> [ListingRequest]
    func submitRequest(_ draft: RequestDraft, for listing: Listing, requester: AuthUser, now: Date) async throws -> ListingRequest
    func withdrawRequest(_ request: ListingRequest) async throws
    /// Reserves the listing for this request and declines every other pending request.
    func accept(_ request: ListingRequest, in listing: Listing, ownerContact: String) async throws
    func decline(_ request: ListingRequest) async throws

    // Safety
    func report(_ listing: Listing, reason: String, reporter: AuthUser) async throws
}

/// Lets the community feature change an item's status in Core Data (saved, listed, rehomed).
@MainActor
protocol ItemStatusUpdating {
    func setStatus(_ status: ItemStatus, forItemWithID id: UUID, on date: Date) throws
}

typealias ItemsStore = ItemsServiceProtocol & ItemStatusUpdating

enum CommunityError: LocalizedError {
    case listingChanged
    case requestNotFound

    var errorDescription: String? {
        switch self {
        case .listingChanged: return "This listing has changed. Pull down to refresh and try again."
        case .requestNotFound: return "That request could not be found. Pull down to refresh."
        }
    }
}
