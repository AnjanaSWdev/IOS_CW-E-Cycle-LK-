//
//  DisposalGuide.swift
//  ecyclelk
//
//  Created by student2 on 2026-10-20.
//

import Foundation

struct DisposalStep: Identifiable, Hashable {
    let title: String
    let detail: String
    var id: String { title }
}

/// Static, bundled disposal guidance (no network, no Core Data).
/// This is general guidance only, not professional hazardous-material advice.
struct DisposalGuide {
    let steps: [DisposalStep]
    /// Shown in the orange "Handle with care" card. `nil` means no warning.
    let warning: String?

    static let disclaimer =
        "This is general guidance only, not professional environmental or hazardous-material advice."

    private static let takeToCentre = DisposalStep(
        title: "Take it to an approved collection centre",
        detail: "Do not place electronic items in household rubbish or roadside bins."
    )

    static func guide(for category: ItemCategory, condition: ItemCondition) -> DisposalGuide {
        let isFaulty = condition != .working

        switch category {
        case .mobilePhones:
            return DisposalGuide(
                steps: [
                    DisposalStep(title: "Turn off and disconnect the item",
                                 detail: "Keep the device dry and away from heat while preparing it."),
                    DisposalStep(title: "Remove personal data and accessories",
                                 detail: "Back up your information, sign out and perform a factory reset where possible."),
                    takeToCentre
                ],
                warning: isFaulty ? "Phones with a damaged or swollen battery can overheat. Do not charge or press on it." : nil
            )

        case .laptops:
            return DisposalGuide(
                steps: [
                    DisposalStep(title: "Back up and wipe your data",
                                 detail: "Copy what you need, sign out of your accounts and reset the laptop where possible."),
                    DisposalStep(title: "Collect the charger and accessories",
                                 detail: "Centres often accept chargers and cables together with the device."),
                    takeToCentre
                ],
                warning: isFaulty ? "A damaged laptop may have a damaged battery. Keep it away from heat and do not charge it." : nil
            )

        case .batteries:
            return DisposalGuide(
                steps: [
                    DisposalStep(title: "Stop using and do not charge it",
                                 detail: "Keep the battery or power bank away from heat, water and direct sunlight."),
                    DisposalStep(title: "Protect the contacts",
                                 detail: "Cover the terminals with tape and store it in a dry, non-metal container."),
                    takeToCentre
                ],
                warning: "Batteries can catch fire if crushed, punctured or short-circuited. Never throw them in a bin or try to open them."
            )

        case .monitors, .televisions:
            return DisposalGuide(
                steps: [
                    DisposalStep(title: "Unplug and let it cool",
                                 detail: "Disconnect all cables and wait before moving the screen."),
                    DisposalStep(title: "Do not open the casing",
                                 detail: "Screens can contain parts that are unsafe to handle. Leave dismantling to the centre."),
                    takeToCentre
                ],
                warning: "Screens are heavy and the glass can break. Carry with two people and avoid pressure on the display."
            )

        case .printers:
            return DisposalGuide(
                steps: [
                    DisposalStep(title: "Unplug and remove cartridges",
                                 detail: "Take out ink or toner cartridges and keep them sealed. Ask the centre if they accept them."),
                    DisposalStep(title: "Remove paper and loose parts",
                                 detail: "Empty the trays so nothing falls out during transport."),
                    takeToCentre
                ],
                warning: nil
            )

        case .cameras:
            return DisposalGuide(
                steps: [
                    DisposalStep(title: "Remove the memory card and battery",
                                 detail: "Save your photos first, then take out the card and the battery."),
                    DisposalStep(title: "Gather lenses, chargers and straps",
                                 detail: "Keep accessories together so they can be handed in with the camera."),
                    takeToCentre
                ],
                warning: isFaulty ? "Remove a damaged battery carefully and keep it separate from the camera." : nil
            )

        case .accessories:
            return DisposalGuide(
                steps: [
                    DisposalStep(title: "Sort cables and small devices",
                                 detail: "Group chargers, cables, earphones and similar items together."),
                    DisposalStep(title: "Check for built-in batteries",
                                 detail: "Earbuds, headsets and speakers often contain small batteries. Do not try to remove them."),
                    takeToCentre
                ],
                warning: nil
            )
        }
    }
}
