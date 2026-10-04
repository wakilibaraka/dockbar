import AppKit

/// The task zone's own value types: what it can show, where each item ended up, and how
/// the user's manual ordering survives items appearing and disappearing.
///
/// These were private to `TaskbarContentView.swift`, which is where they became invisible;
/// they are separate types with their own behaviour, so they get their own file.


enum TaskZoneItem {
    case window(WindowInfo)
    case group(AppGroup)
}

struct TaskZonePlacedView {
    let view: NSView
    let zone: TaskbarWindowZone
}

struct TaskZoneOrderingState {
    private(set) var nonPositionedItemIDs: [String] = []
    private(set) var userPositionedRanks: [String: Int] = [:]
    private var recentlyDepartedItemIDs: [String: Date] = [:]

    mutating func reconcile(currentIDs: [String]) {
        let currentIDSet = Set(currentIDs)
        let now = Date()
        
        recentlyDepartedItemIDs = recentlyDepartedItemIDs.filter { now.timeIntervalSince($0.value) < 10.0 }
        for id in currentIDs { recentlyDepartedItemIDs.removeValue(forKey: id) }
        
        let knownItemIDs = Set(nonPositionedItemIDs).union(userPositionedRanks.keys)
        let departedItemIDs = knownItemIDs.subtracting(currentIDSet)
        for id in departedItemIDs {
            if recentlyDepartedItemIDs[id] == nil {
                recentlyDepartedItemIDs[id] = now
            }
        }
        
        let activeOrRecentlyDeparted = currentIDSet.union(recentlyDepartedItemIDs.keys)
        
        userPositionedRanks = userPositionedRanks.filter { activeOrRecentlyDeparted.contains($0.key) }
        nonPositionedItemIDs = nonPositionedItemIDs.filter {
            activeOrRecentlyDeparted.contains($0) && userPositionedRanks[$0] == nil
        }

        let knownActive = Set(nonPositionedItemIDs).union(userPositionedRanks.keys)
        let newItemIDs = currentIDs.filter { !knownActive.contains($0) }
        for itemID in newItemIDs {
            nonPositionedItemIDs.append(itemID)
        }
    }

    mutating func applyManualOrder(_ orderedIDs: [String], userPositionedItemID: String) {
        var positionedItemIDs = Set(userPositionedRanks.keys)
        positionedItemIDs.insert(userPositionedItemID)

        userPositionedRanks = [:]
        nonPositionedItemIDs = []

        for (index, itemID) in orderedIDs.enumerated() {
            if positionedItemIDs.contains(itemID) {
                userPositionedRanks[itemID] = index
            } else {
                nonPositionedItemIDs.append(itemID)
            }
        }
    }

    func arrangedIDs(for currentIDs: [String]) -> [String] {
        guard !currentIDs.isEmpty else {
            return []
        }

        let currentIDSet = Set(currentIDs)
        var arrangedIDs = Array<String?>(repeating: nil, count: currentIDs.count)
        let positionedItems = userPositionedRanks
            .filter { currentIDSet.contains($0.key) }
            .sorted {
                if $0.value != $1.value {
                    return $0.value < $1.value
                }

                return $0.key < $1.key
            }

        for (itemID, desiredRank) in positionedItems {
            var targetIndex = min(max(desiredRank, 0), arrangedIDs.count - 1)

            while targetIndex < arrangedIDs.count, arrangedIDs[targetIndex] != nil {
                targetIndex += 1
            }

            if targetIndex >= arrangedIDs.count,
               let fallbackIndex = arrangedIDs.indices.last(where: { arrangedIDs[$0] == nil }) {
                targetIndex = fallbackIndex
            }

            arrangedIDs[targetIndex] = itemID
        }

        var seenNonPositioned = Set<String>()
        let fallbackNonPositionedIDs = currentIDs.filter {
            userPositionedRanks[$0] == nil && seenNonPositioned.insert($0).inserted
        }
        let orderedNonPositionedIDs = nonPositionedItemIDs.filter {
            currentIDSet.contains($0) && userPositionedRanks[$0] == nil
        } + fallbackNonPositionedIDs.filter {
            !nonPositionedItemIDs.contains($0)
        }

        var nonPositionedIterator = orderedNonPositionedIDs.makeIterator()

        for index in arrangedIDs.indices where arrangedIDs[index] == nil {
            arrangedIDs[index] = nonPositionedIterator.next()
        }

        return arrangedIDs.compactMap { $0 }
    }
}
