//
//  FireStoreCommunityService.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-26.
//

import Foundation
import FirebaseFirestore

/// Firestore implementation of the community backend.
///
/// Collections:
///   listings/{listingID}
///   requests/{listingID}_{requesterUID}
///   reports/{autoID}
/// The security rules in firestore.rules decide who may read and change each document.
@MainActor
final class FirestoreCommunityService: CommunityServiceProtocol {
    private let db = Firestore.firestore()
    private var listingsRef: CollectionReference { db.collection("listings") }
    private var requestsRef: CollectionReference { db.collection("requests") }

    // MARK: - Listings

    func fetchOpenListings() async throws -> [Listing] {
        let snapshot = try await listingsRef
            .whereField("status", isEqualTo: ListingStatus.open.rawValue)
            .limit(to: 200)
            .getDocuments()
        return snapshot.documents.compactMap { Self.listing(from: $0) }
    }

    func fetchListings(ownerUID: String) async throws -> [Listing] {
        let snapshot = try await listingsRef
            .whereField("ownerUID", isEqualTo: ownerUID)
            .getDocuments()
        return snapshot.documents.compactMap { Self.listing(from: $0) }
    }

    func createListing(_ draft: ListingDraft, owner: AuthUser, now: Date) async throws -> Listing {
        let reference = listingsRef.document()
        let expires = now.addingTimeInterval(Double(Listing.lifetimeDays) * 86_400)

        var data: [String: Any] = [
            "ownerUID": owner.uid,
            "ownerName": owner.publicName,
            "title": draft.trimmedTitle,
            "category": draft.category.rawValue,
            "condition": draft.condition.rawValue,
            "description": draft.trimmedDescription,
            "mode": draft.mode.rawValue,
            "priceLKR": draft.priceLKR,
            "district": draft.district,
            "handoverNote": draft.trimmedHandoverNote,
            "status": ListingStatus.open.rawValue,
            "requestCount": 0,
            "createdAt": Timestamp(date: now),
            "expiresAt": Timestamp(date: expires)
        ]
        if let itemID = draft.sourceItemID { data["sourceItemID"] = itemID.uuidString }
        try await reference.setData(data)

        return Listing(id: reference.documentID, ownerUID: owner.uid, ownerName: owner.publicName,
                       sourceItemID: draft.sourceItemID?.uuidString, title: draft.trimmedTitle,
                       category: draft.category, condition: draft.condition,
                       description: draft.trimmedDescription, mode: draft.mode, priceLKR: draft.priceLKR,
                       district: draft.district, handoverNote: draft.trimmedHandoverNote,
                       createdAt: now, expiresAt: expires)
    }

    func close(_ listing: Listing, as status: ListingStatus) async throws {
        let related = try await requestDocuments(for: listing)
        let batch = db.batch()
        batch.updateData(["status": status.rawValue], forDocument: listingsRef.document(listing.id))
        for document in related {
            let current = RequestStatus(rawValue: document.data()["status"] as? String ?? "")
            if current == .pending {
                batch.updateData(["status": RequestStatus.declined.rawValue], forDocument: document.reference)
            } else if current == .accepted {
                batch.updateData(["status": RequestStatus.cancelled.rawValue], forDocument: document.reference)
            }
        }
        try await batch.commit()
    }

    func reopen(_ listing: Listing) async throws {
        let related = try await requestDocuments(for: listing)
        let batch = db.batch()
        batch.updateData([
            "status": ListingStatus.open.rawValue,
            "reservedForUID": FieldValue.delete(),
            "reservedForName": FieldValue.delete()
        ], forDocument: listingsRef.document(listing.id))
        for document in related where (document.data()["status"] as? String) == RequestStatus.accepted.rawValue {
            batch.updateData(["status": RequestStatus.cancelled.rawValue], forDocument: document.reference)
        }
        try await batch.commit()
    }

    func complete(_ listing: Listing) async throws {
        let related = try await requestDocuments(for: listing)
        let batch = db.batch()
        batch.updateData(["status": ListingStatus.completed.rawValue], forDocument: listingsRef.document(listing.id))
        for document in related where (document.data()["status"] as? String) == RequestStatus.accepted.rawValue {
            batch.updateData(["status": RequestStatus.completed.rawValue], forDocument: document.reference)
        }
        try await batch.commit()
    }

    // MARK: - Requests

    func fetchRequests(forListing listingID: String, ownerUID: String) async throws -> [ListingRequest] {
        // The ownerUID filter is required: Firestore only allows a query the security rules can prove is allowed.
        let snapshot = try await requestsRef
            .whereField("listingID", isEqualTo: listingID)
            .whereField("ownerUID", isEqualTo: ownerUID)
            .getDocuments()
        return snapshot.documents.compactMap { Self.request(from: $0) }
    }

    func fetchRequests(byRequester uid: String) async throws -> [ListingRequest] {
        let snapshot = try await requestsRef
            .whereField("requesterUID", isEqualTo: uid)
            .getDocuments()
        return snapshot.documents.compactMap { Self.request(from: $0) }
    }

    func submitRequest(_ draft: RequestDraft, for listing: Listing, requester: AuthUser, now: Date) async throws -> ListingRequest {
        let id = ListingRequest.makeID(listingID: listing.id, requesterUID: requester.uid)
        let phone = RequestDraft.normalizedPhone(draft.phone) ?? draft.phone

        let data: [String: Any] = [
            "listingID": listing.id,
            "listingTitle": listing.title,
            "ownerUID": listing.ownerUID,
            "requesterUID": requester.uid,
            "requesterName": requester.publicName,
            "purpose": draft.purpose.rawValue,
            "message": draft.trimmedMessage,
            "contactPhone": phone,
            "status": RequestStatus.pending.rawValue,
            "ownerContact": "",
            "createdAt": Timestamp(date: now)
        ]

        // One batch: the request and the listing's counter change together or not at all.
        let batch = db.batch()
        batch.setData(data, forDocument: requestsRef.document(id))
        batch.updateData(["requestCount": FieldValue.increment(Int64(1))], forDocument: listingsRef.document(listing.id))
        try await batch.commit()

        return ListingRequest(id: id, listingID: listing.id, listingTitle: listing.title, ownerUID: listing.ownerUID,
                              requesterUID: requester.uid, requesterName: requester.publicName,
                              purpose: draft.purpose, message: draft.trimmedMessage, contactPhone: phone,
                              status: .pending, ownerContact: "", createdAt: now)
    }

    func withdrawRequest(_ request: ListingRequest) async throws {
        try await requestsRef.document(request.id).updateData(["status": RequestStatus.withdrawn.rawValue])
    }

    func accept(_ request: ListingRequest, in listing: Listing, ownerContact: String) async throws {
        let current = try await listingsRef.document(listing.id).getDocument()
        guard (current.data()?["status"] as? String) == ListingStatus.open.rawValue else {
            throw CommunityError.listingChanged
        }
        let related = try await requestDocuments(for: listing)
        guard related.contains(where: { $0.documentID == request.id }) else {
            throw CommunityError.requestNotFound
        }

        let batch = db.batch()
        batch.updateData([
            "status": ListingStatus.reserved.rawValue,
            "reservedForUID": request.requesterUID,
            "reservedForName": request.requesterName
        ], forDocument: listingsRef.document(listing.id))

        for document in related where (document.data()["status"] as? String) == RequestStatus.pending.rawValue {
            if document.documentID == request.id {
                batch.updateData(["status": RequestStatus.accepted.rawValue, "ownerContact": ownerContact],
                                 forDocument: document.reference)
            } else {
                batch.updateData(["status": RequestStatus.declined.rawValue], forDocument: document.reference)
            }
        }
        try await batch.commit()
    }

    func decline(_ request: ListingRequest) async throws {
        try await requestsRef.document(request.id).updateData(["status": RequestStatus.declined.rawValue])
    }

    // MARK: - Safety

    func report(_ listing: Listing, reason: String, reporter: AuthUser) async throws {
        _ = try await db.collection("reports").addDocument(data: [
            "listingID": listing.id,
            "listingTitle": listing.title,
            "reportedOwnerUID": listing.ownerUID,
            "reporterUID": reporter.uid,
            "reason": reason,
            "createdAt": Timestamp(date: Date())
        ])
    }

    // MARK: - Helpers

    private func requestDocuments(for listing: Listing) async throws -> [QueryDocumentSnapshot] {
        try await requestsRef
            .whereField("listingID", isEqualTo: listing.id)
            .whereField("ownerUID", isEqualTo: listing.ownerUID)
            .getDocuments()
            .documents
    }

    private static func listing(from document: DocumentSnapshot) -> Listing? {
        guard let data = document.data(),
              let ownerUID = data["ownerUID"] as? String,
              let title = data["title"] as? String,
              let category = ItemCategory(rawValue: data["category"] as? String ?? ""),
              let condition = ListingCondition(rawValue: data["condition"] as? String ?? ""),
              let mode = ListingMode(rawValue: data["mode"] as? String ?? ""),
              let status = ListingStatus(rawValue: data["status"] as? String ?? "")
        else { return nil }

        let created = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        return Listing(
            id: document.documentID,
            ownerUID: ownerUID,
            ownerName: data["ownerName"] as? String ?? "",
            sourceItemID: data["sourceItemID"] as? String,
            title: title,
            category: category,
            condition: condition,
            description: data["description"] as? String ?? "",
            mode: mode,
            priceLKR: data["priceLKR"] as? Int ?? 0,
            district: data["district"] as? String ?? "",
            handoverNote: data["handoverNote"] as? String ?? "",
            status: status,
            requestCount: data["requestCount"] as? Int ?? 0,
            createdAt: created,
            expiresAt: (data["expiresAt"] as? Timestamp)?.dateValue(),
            reservedForUID: data["reservedForUID"] as? String,
            reservedForName: data["reservedForName"] as? String
        )
    }

    private static func request(from document: DocumentSnapshot) -> ListingRequest? {
        guard let data = document.data(),
              let listingID = data["listingID"] as? String,
              let ownerUID = data["ownerUID"] as? String,
              let requesterUID = data["requesterUID"] as? String,
              let status = RequestStatus(rawValue: data["status"] as? String ?? "")
        else { return nil }

        return ListingRequest(
            id: document.documentID,
            listingID: listingID,
            listingTitle: data["listingTitle"] as? String ?? "",
            ownerUID: ownerUID,
            requesterUID: requesterUID,
            requesterName: data["requesterName"] as? String ?? "Community member",
            purpose: RequestPurpose(rawValue: data["purpose"] as? String ?? "") ?? .useIt,
            message: data["message"] as? String ?? "",
            contactPhone: data["contactPhone"] as? String ?? "",
            status: status,
            ownerContact: data["ownerContact"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
