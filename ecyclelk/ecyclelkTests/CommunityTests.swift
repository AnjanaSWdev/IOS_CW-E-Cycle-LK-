//
//  CommunityTests.swift
//  ecyclelkTests
//
//  Created by student2 on 2026-10-26.
//

import Foundation
import Testing
@testable import ecyclelk

// MARK: - Fakes

@MainActor
private final class FakeCommunityService: CommunityServiceProtocol {
    var listings: [Listing] = []
    var requests: [ListingRequest] = []
    var failWith: Error?
    private(set) var reports: [String] = []

    private func check() throws { if let failWith { throw failWith } }

    func fetchOpenListings() async throws -> [Listing] {
        try check()
        return listings.filter { $0.status == .open }
    }

    func fetchListings(ownerUID: String) async throws -> [Listing] {
        try check()
        return listings.filter { $0.ownerUID == ownerUID }
    }

    func createListing(_ draft: ListingDraft, owner: AuthUser, now: Date) async throws -> Listing {
        try check()
        let listing = Listing(id: "L\(listings.count + 1)", ownerUID: owner.uid, ownerName: owner.publicName,
                              sourceItemID: draft.sourceItemID?.uuidString, title: draft.trimmedTitle,
                              category: draft.category, condition: draft.condition,
                              description: draft.trimmedDescription, mode: draft.mode, priceLKR: draft.priceLKR,
                              district: draft.district, createdAt: now)
        listings.append(listing)
        return listing
    }

    func close(_ listing: Listing, as status: ListingStatus) async throws {
        try check()
        setListing(listing.id) { $0.status = status }
        for index in requests.indices where requests[index].listingID == listing.id {
            if requests[index].status == .pending { requests[index].status = .declined }
            if requests[index].status == .accepted { requests[index].status = .cancelled }
        }
    }

    func reopen(_ listing: Listing) async throws {
        try check()
        setListing(listing.id) { $0.status = .open; $0.reservedForUID = nil; $0.reservedForName = nil }
        for index in requests.indices where requests[index].listingID == listing.id && requests[index].status == .accepted {
            requests[index].status = .cancelled
        }
    }

    func complete(_ listing: Listing) async throws {
        try check()
        setListing(listing.id) { $0.status = .completed }
        for index in requests.indices where requests[index].listingID == listing.id && requests[index].status == .accepted {
            requests[index].status = .completed
        }
    }

    func fetchRequests(forListing listingID: String, ownerUID: String) async throws -> [ListingRequest] {
        try check()
        return requests.filter { $0.listingID == listingID && $0.ownerUID == ownerUID }
    }

    func fetchRequests(byRequester uid: String) async throws -> [ListingRequest] {
        try check()
        return requests.filter { $0.requesterUID == uid }
    }

    func submitRequest(_ draft: RequestDraft, for listing: Listing, requester: AuthUser, now: Date) async throws -> ListingRequest {
        try check()
        let request = ListingRequest(
            id: ListingRequest.makeID(listingID: listing.id, requesterUID: requester.uid),
            listingID: listing.id, listingTitle: listing.title, ownerUID: listing.ownerUID,
            requesterUID: requester.uid, requesterName: requester.publicName, purpose: draft.purpose,
            message: draft.trimmedMessage, contactPhone: draft.phone, status: .pending, ownerContact: "", createdAt: now
        )
        requests.append(request)
        setListing(listing.id) { $0.requestCount += 1 }
        return request
    }

    func withdrawRequest(_ request: ListingRequest) async throws {
        try check()
        if let index = requests.firstIndex(where: { $0.id == request.id }) { requests[index].status = .withdrawn }
    }

    func accept(_ request: ListingRequest, in listing: Listing, ownerContact: String) async throws {
        try check()
        setListing(listing.id) {
            $0.status = .reserved
            $0.reservedForUID = request.requesterUID
            $0.reservedForName = request.requesterName
        }
        for index in requests.indices where requests[index].listingID == listing.id && requests[index].status == .pending {
            if requests[index].id == request.id {
                requests[index].status = .accepted
                requests[index].ownerContact = ownerContact
            } else {
                requests[index].status = .declined
            }
        }
    }

    func decline(_ request: ListingRequest) async throws {
        try check()
        if let index = requests.firstIndex(where: { $0.id == request.id }) { requests[index].status = .declined }
    }

    func report(_ listing: Listing, reason: String, reporter: AuthUser) async throws {
        try check()
        reports.append(reason)
    }

    private func setListing(_ id: String, _ change: (inout Listing) -> Void) {
        if let index = listings.firstIndex(where: { $0.id == id }) { change(&listings[index]) }
    }
}

@MainActor
private final class FakeItemsStore: ItemsServiceProtocol, ItemStatusUpdating {
    var items: [ItemRecord]
    init(_ items: [ItemRecord]) { self.items = items }

    func fetchItems(ownerUID: String) throws -> [ItemRecord] {
        items.filter { $0.status != .recycled && $0.status != .rehomed }
    }
    func addItem(_ draft: ItemDraft, ownerUID: String) throws -> ItemRecord { throw ItemsServiceError.notFound }
    func updateItem(id: UUID, with draft: ItemDraft) throws {}
    func deleteItem(id: UUID) throws {}

    func setStatus(_ status: ItemStatus, forItemWithID id: UUID, on date: Date) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else { throw ItemsServiceError.notFound }
        items[index].status = status
    }

    func status(of id: UUID) -> ItemStatus? { items.first { $0.id == id }?.status }
}

// MARK: - Helpers

private let now = Date(timeIntervalSince1970: 1_790_000_000)
private let owner = AuthUser(uid: "owner", email: "owner@example.com", name: "Nimali Perera")
private let buyer = AuthUser(uid: "buyer", email: "buyer@example.com", name: "Kasun Silva")
private let buyer2 = AuthUser(uid: "buyer2", email: "buyer2@example.com", name: "Ayesha Fernando")

private func item(_ name: String = "Old laptop", category: ItemCategory = .laptops,
                  condition: ItemCondition = .damaged, status: ItemStatus = .saved) -> ItemRecord {
    ItemRecord(id: UUID(), name: name, category: category, condition: condition, notes: "Screen cracked, works fine otherwise",
               weightKg: 2, dateAdded: now, status: status)
}

private func validDraft(for item: ItemRecord) -> ListingDraft {
    var draft = ListingDraft()
    draft.apply(item)
    draft.description = "Cracked screen but boots and runs well. Charger included."
    draft.district = "Colombo"
    draft.confirmsDataRemoved = true
    draft.confirmsBatterySafe = true
    draft.confirmsOwnership = true
    return draft
}

private let goodRequest = RequestDraft(purpose: .repairIt, message: "I repair laptops as a hobby and would love this.", phone: "077 123 4567")

@MainActor
private func makeViewModel(_ user: AuthUser, service: FakeCommunityService, store: FakeItemsStore,
                           at date: Date = now) -> CommunityViewModel {
    CommunityViewModel(service: service, items: store, user: user, now: { date })
}

// MARK: - Draft rules

@MainActor
struct ListingDraftTests {
    @Test func aCompleteDraftHasNoProblems() {
        #expect(validDraft(for: item()).problems().isEmpty)
    }

    @Test func applyingAnItemPrefillsTheForm() {
        var draft = ListingDraft()
        let source = item("Nokia 3310", category: .mobilePhones, condition: .notWorking)
        draft.apply(source)
        #expect(draft.sourceItemID == source.id)
        #expect(draft.title == "Nokia 3310")
        #expect(draft.category == .mobilePhones)
        #expect(draft.condition == .forParts)
    }

    @Test func damagedBatteriesCanNeverBeListed() {
        var draft = validDraft(for: item("Spare battery", category: .batteries, condition: .damaged))
        draft.condition = .needsRepair
        #expect(draft.problems().contains(.hazardousBattery))
        draft.condition = .working
        #expect(!draft.problems().contains(.hazardousBattery))
    }

    @Test func devicesThatHoldDataNeedTheWipeConfirmation() {
        var draft = validDraft(for: item(category: .laptops))
        draft.confirmsDataRemoved = false
        #expect(draft.problems().contains(.dataNotRemoved))

        var printer = validDraft(for: item("Printer", category: .printers))
        printer.confirmsDataRemoved = false
        #expect(!printer.problems().contains(.dataNotRemoved))
    }

    @Test func salesNeedASensiblePrice() {
        var draft = validDraft(for: item())
        draft.mode = .sale
        #expect(draft.problems().contains(.noPrice))
        draft.priceText = "Rs. 15,000"
        #expect(draft.priceLKR == 15_000)
        #expect(draft.problems().isEmpty)
        draft.priceText = "5000000"
        #expect(draft.problems().contains(.priceTooHigh))
    }

    @Test func givingAwayAlwaysMeansFree() {
        var draft = validDraft(for: item())
        draft.mode = .giveaway
        draft.priceText = "9999"
        #expect(draft.priceLKR == 0)
    }

    @Test func requiredFieldsAreChecked() {
        let problems = ListingDraft().problems()
        #expect(problems.contains(.noItem))
        #expect(problems.contains(.titleTooShort))
        #expect(problems.contains(.descriptionTooShort))
        #expect(problems.contains(.noDistrict))
        #expect(problems.contains(.batteryNotChecked))
        #expect(problems.contains(.ownershipNotConfirmed))
    }

    @Test func requestDraftChecksMessageAndPhone() {
        #expect(goodRequest.problems().isEmpty)
        #expect(RequestDraft(message: "hi", phone: "0771234567").problems() == [.messageTooShort])
        #expect(RequestDraft(message: "I would like to repair this please", phone: "123").problems() == [.invalidPhone])
        #expect(RequestDraft(message: String(repeating: "a", count: 301), phone: "0771234567").problems() == [.messageTooLong])
    }

    @Test func phoneNumbersAreNormalised() {
        #expect(RequestDraft.normalizedPhone("077 123 4567") == "0771234567")
        #expect(RequestDraft.normalizedPhone("+94 77 123 4567") == "+94771234567")
        #expect(RequestDraft.normalizedPhone("(011) 234-5678") == "0112345678")
        #expect(RequestDraft.normalizedPhone("call me") == nil)
        #expect(RequestDraft.normalizedPhone("12345") == nil)
    }
}

// MARK: - Listing rules

@MainActor
struct ListingRuleTests {
    private func listing(status: ListingStatus = .open, requests: Int = 0, age days: Double = 0) -> Listing {
        Listing(id: "L1", ownerUID: "owner", title: "Laptop", status: status, requestCount: requests,
                createdAt: now.addingTimeInterval(-days * 86_400))
    }

    @Test func listingsLastFourteenDays() {
        let fresh = listing()
        #expect(fresh.daysLeft(now: now) == 14)
        #expect(!fresh.isExpired(now: now))
        #expect(fresh.isExpired(now: now.addingTimeInterval(14 * 86_400)))
        #expect(!listing(status: .reserved, age: 30).isExpired(now: now))   // only open listings expire
    }

    @Test func recyclingIsSuggestedAfterAWeekWithoutRequests() {
        #expect(!listing(age: 3).shouldSuggestRecycling(now: now))
        #expect(listing(age: 8).shouldSuggestRecycling(now: now))
        #expect(!listing(requests: 1, age: 8).shouldSuggestRecycling(now: now))
        #expect(!listing(status: .reserved, age: 8).shouldSuggestRecycling(now: now))
    }

    @Test func whoMayRequest() {
        #expect(listing().requestBlock(for: "owner", hasExistingRequest: false, now: now) == .ownListing)
        #expect(listing(status: .reserved).requestBlock(for: "x", hasExistingRequest: false, now: now) == .notOpen)
        #expect(listing(age: 20).requestBlock(for: "x", hasExistingRequest: false, now: now) == .expired)
        #expect(listing().requestBlock(for: "x", hasExistingRequest: true, now: now) == .alreadyRequested)
        #expect(listing(requests: 15).requestBlock(for: "x", hasExistingRequest: false, now: now) == .full)
        #expect(listing().requestBlock(for: "x", hasExistingRequest: false, now: now) == nil)
    }

    @Test func priceTextAndPublicName() {
        #expect(listing().priceText == "Free")
        #expect(AuthUser(uid: "1", email: "a@b.c", name: "Nimali Perera").publicName == "Nimali P.")
        #expect(AuthUser(uid: "1", email: "a@b.c", name: "Nimali").publicName == "Nimali")
        #expect(AuthUser(uid: "1", email: "a@b.c", name: "").publicName == "Community member")
    }

    @Test func requestIDsAreUniquePerPersonAndListing() {
        #expect(ListingRequest.makeID(listingID: "L1", requesterUID: "u1") == "L1_u1")
    }

    @Test func conditionSuggestionFollowsTheSavedItem() {
        #expect(ListingCondition.suggested(for: .working) == .working)
        #expect(ListingCondition.suggested(for: .damaged) == .needsRepair)
        #expect(ListingCondition.suggested(for: .notWorking) == .forParts)
    }
}

// MARK: - The whole flow

@MainActor
struct CommunityViewModelTests {

    @Test func listingAnItemMarksItListedAndHidesItFromThePlanChoices() async throws {
        let laptop = item()
        let store = FakeItemsStore([laptop])
        let service = FakeCommunityService()
        let viewModel = makeViewModel(owner, service: service, store: store)
        viewModel.loadAvailableItems()
        #expect(viewModel.availableItems.count == 1)

        let success = await viewModel.createListing(validDraft(for: laptop))

        #expect(success)
        #expect(store.status(of: laptop.id) == .listed)
        #expect(viewModel.myListings.count == 1)
        #expect(viewModel.availableItems.isEmpty)
        #expect(viewModel.section == .mine)
    }

    @Test func aDraftWithProblemsIsNeverSent() async {
        let service = FakeCommunityService()
        let viewModel = makeViewModel(owner, service: service, store: FakeItemsStore([]))
        let success = await viewModel.createListing(ListingDraft())
        #expect(!success)
        #expect(viewModel.errorMessage != nil)
        #expect(service.listings.isEmpty)
    }

    @Test func theFeedHidesYourOwnAndExpiredListingsAndAppliesFilters() async {
        let service = FakeCommunityService()
        service.listings = [
            Listing(id: "mine", ownerUID: "buyer", title: "My own", category: .laptops, district: "Colombo", createdAt: now),
            Listing(id: "old", ownerUID: "owner", title: "Too old", category: .laptops, district: "Colombo",
                    createdAt: now.addingTimeInterval(-20 * 86_400)),
            Listing(id: "phone", ownerUID: "owner", title: "Nokia phone", category: .mobilePhones, mode: .sale,
                    priceLKR: 3000, district: "Kandy", createdAt: now),
            Listing(id: "lap", ownerUID: "owner", title: "Dell laptop", category: .laptops, district: "Colombo", createdAt: now)
        ]
        let viewModel = makeViewModel(buyer, service: service, store: FakeItemsStore([]))
        await viewModel.refresh()

        #expect(Set(viewModel.visibleFeed.map(\.id)) == ["phone", "lap"])

        viewModel.categoryFilter = .laptops
        #expect(viewModel.visibleFeed.map(\.id) == ["lap"])
        viewModel.clearFilters()

        viewModel.modeFilter = .sale
        #expect(viewModel.visibleFeed.map(\.id) == ["phone"])
        viewModel.clearFilters()

        viewModel.districtFilter = "Kandy"
        #expect(viewModel.visibleFeed.map(\.id) == ["phone"])
        viewModel.clearFilters()

        viewModel.searchText = "dell"
        #expect(viewModel.visibleFeed.map(\.id) == ["lap"])
    }

    @Test func requestingAndDuplicateRequests() async {
        let service = FakeCommunityService()
        service.listings = [Listing(id: "L1", ownerUID: "owner", title: "Laptop", district: "Colombo", createdAt: now)]
        let viewModel = makeViewModel(buyer, service: service, store: FakeItemsStore([]))
        await viewModel.refresh()
        let listing = service.listings[0]

        #expect(await viewModel.submitRequest(goodRequest, for: listing))
        #expect(viewModel.myRequests.count == 1)
        #expect(viewModel.existingRequest(for: "L1")?.status == .pending)

        #expect(!(await viewModel.submitRequest(goodRequest, for: listing)))
        #expect(viewModel.errorMessage == RequestBlock.alreadyRequested.message)
        #expect(service.requests.count == 1)
    }

    @Test func youCannotRequestYourOwnItemOrSendABadRequest() async {
        let service = FakeCommunityService()
        service.listings = [Listing(id: "L1", ownerUID: "owner", title: "Laptop", createdAt: now)]
        let ownerVM = makeViewModel(owner, service: service, store: FakeItemsStore([]))
        #expect(!(await ownerVM.submitRequest(goodRequest, for: service.listings[0])))

        let buyerVM = makeViewModel(buyer, service: service, store: FakeItemsStore([]))
        #expect(!(await buyerVM.submitRequest(RequestDraft(message: "hi", phone: ""), for: service.listings[0])))
        #expect(service.requests.isEmpty)
    }

    @Test func acceptingReservesTheListingAndDeclinesEveryoneElse() async throws {
        let laptop = item()
        let store = FakeItemsStore([laptop])
        let service = FakeCommunityService()
        let ownerVM = makeViewModel(owner, service: service, store: store)
        ownerVM.loadAvailableItems()
        _ = await ownerVM.createListing(validDraft(for: laptop))
        let listing = try #require(ownerVM.myListings.first)

        let buyerVM = makeViewModel(buyer, service: service, store: FakeItemsStore([]))
        let buyer2VM = makeViewModel(buyer2, service: service, store: FakeItemsStore([]))
        _ = await buyerVM.submitRequest(goodRequest, for: listing)
        _ = await buyer2VM.submitRequest(goodRequest, for: listing)

        await ownerVM.loadRequests(for: listing)
        let chosen = try #require(ownerVM.requestsByListing[listing.id]?.first { $0.requesterUID == "buyer" })

        // A number that is not a phone number is refused.
        #expect(!(await ownerVM.accept(chosen, in: listing, ownerContact: "soon")))

        #expect(await ownerVM.accept(chosen, in: listing, ownerContact: "071 555 0000"))
        #expect(ownerVM.listing(withID: listing.id)?.status == .reserved)
        #expect(ownerVM.listing(withID: listing.id)?.reservedForUID == "buyer")
        #expect(service.requests.first { $0.requesterUID == "buyer" }?.status == .accepted)
        #expect(service.requests.first { $0.requesterUID == "buyer" }?.ownerContact == "0715550000")
        #expect(service.requests.first { $0.requesterUID == "buyer2" }?.status == .declined)

        // Nobody else can be accepted now.
        let other = try #require(service.requests.first { $0.requesterUID == "buyer2" })
        #expect(!(await ownerVM.accept(other, in: ownerVM.listing(withID: listing.id)!, ownerContact: "0715550000")))
    }

    @Test func handingOverGivesTheItemASecondLife() async throws {
        let laptop = item()
        let store = FakeItemsStore([laptop])
        let service = FakeCommunityService()
        let ownerVM = makeViewModel(owner, service: service, store: store)
        ownerVM.loadAvailableItems()
        _ = await ownerVM.createListing(validDraft(for: laptop))
        let listing = try #require(ownerVM.myListings.first)
        let buyerVM = makeViewModel(buyer, service: service, store: FakeItemsStore([]))
        _ = await buyerVM.submitRequest(goodRequest, for: listing)
        await ownerVM.loadRequests(for: listing)
        let request = try #require(ownerVM.requestsByListing[listing.id]?.first)
        _ = await ownerVM.accept(request, in: listing, ownerContact: "0715550000")

        #expect(await ownerVM.markHandedOver(ownerVM.listing(withID: listing.id)!))
        #expect(ownerVM.listing(withID: listing.id)?.status == .completed)
        #expect(store.status(of: laptop.id) == .rehomed)
        #expect(service.requests.first?.status == .completed)
    }

    @Test func reopeningReleasesTheRequesterAndKeepsTheItemListed() async throws {
        let laptop = item()
        let store = FakeItemsStore([laptop])
        let service = FakeCommunityService()
        let ownerVM = makeViewModel(owner, service: service, store: store)
        ownerVM.loadAvailableItems()
        _ = await ownerVM.createListing(validDraft(for: laptop))
        let listing = try #require(ownerVM.myListings.first)
        let buyerVM = makeViewModel(buyer, service: service, store: FakeItemsStore([]))
        _ = await buyerVM.submitRequest(goodRequest, for: listing)
        await ownerVM.loadRequests(for: listing)
        let request = try #require(ownerVM.requestsByListing[listing.id]?.first)
        _ = await ownerVM.accept(request, in: listing, ownerContact: "0715550000")

        #expect(await ownerVM.reopen(ownerVM.listing(withID: listing.id)!))
        #expect(ownerVM.listing(withID: listing.id)?.status == .open)
        #expect(ownerVM.listing(withID: listing.id)?.reservedForUID == nil)
        #expect(service.requests.first?.status == .cancelled)
        #expect(store.status(of: laptop.id) == .listed)
    }

    @Test func withdrawingBringsTheItemBackToMyItems() async throws {
        let laptop = item()
        let store = FakeItemsStore([laptop])
        let ownerVM = makeViewModel(owner, service: FakeCommunityService(), store: store)
        ownerVM.loadAvailableItems()
        _ = await ownerVM.createListing(validDraft(for: laptop))
        let listing = try #require(ownerVM.myListings.first)

        #expect(await ownerVM.withdraw(listing))
        #expect(ownerVM.listing(withID: listing.id)?.status == .withdrawn)
        #expect(store.status(of: laptop.id) == .saved)
        #expect(ownerVM.availableItems.count == 1)
    }

    @Test func expiredListingsAreClosedAndTheItemComesBack() async throws {
        let laptop = item(status: .listed)
        let store = FakeItemsStore([laptop])
        let service = FakeCommunityService()
        service.listings = [Listing(id: "L1", ownerUID: "owner", sourceItemID: laptop.id.uuidString, title: "Old laptop",
                                    createdAt: now.addingTimeInterval(-15 * 86_400))]
        let ownerVM = makeViewModel(owner, service: service, store: store)

        await ownerVM.refresh()

        #expect(ownerVM.myListings.first?.status == .expired)
        #expect(service.listings.first?.status == .expired)
        #expect(store.status(of: laptop.id) == .saved)
    }

    @Test func requesterCanWithdrawOnlyWhilePending() async {
        let service = FakeCommunityService()
        service.listings = [Listing(id: "L1", ownerUID: "owner", title: "Laptop", createdAt: now)]
        let viewModel = makeViewModel(buyer, service: service, store: FakeItemsStore([]))
        _ = await viewModel.submitRequest(goodRequest, for: service.listings[0])
        let request = viewModel.myRequests[0]

        #expect(await viewModel.withdrawRequest(request))
        #expect(viewModel.myRequests[0].status == .withdrawn)
        #expect(!(await viewModel.withdrawRequest(viewModel.myRequests[0])))
    }

    @Test func serviceFailuresBecomeMessages() async {
        let service = FakeCommunityService()
        service.failWith = CommunityError.listingChanged
        let viewModel = makeViewModel(buyer, service: service, store: FakeItemsStore([]))
        await viewModel.refresh()
        #expect(viewModel.errorMessage == CommunityError.listingChanged.errorDescription)
    }

    @Test func reportingIsRecorded() async {
        let service = FakeCommunityService()
        let viewModel = makeViewModel(buyer, service: service, store: FakeItemsStore([]))
        await viewModel.report(Listing(id: "L1", ownerUID: "owner", title: "x"), reason: "Scam or misleading")
        #expect(service.reports == ["Scam or misleading"])
        #expect(viewModel.noticeMessage != nil)
    }
}

// MARK: - Stats

@MainActor
struct RehomedStatsTests {
    @Test func rehomedItemsAreNotActiveAndCountTowardsCompletion() {
        let calendar = Calendar(identifier: .gregorian)
        let items = [
            item(status: .saved),
            item(status: .rehomed),
            item(status: .recycled),
            item(status: .listed)
        ]
        let stats = RecyclingStats.make(from: items, now: now, calendar: calendar)
        #expect(stats.itemsRehomed == 1)
        #expect(stats.itemsRecycled == 1)
        #expect(stats.activeItems == 2)
        #expect(stats.completionRatePercent == 50)
    }
}
