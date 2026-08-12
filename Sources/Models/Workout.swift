import Foundation

/// Hvor god en enkelt rep var.
///
/// Bevidst tre grove kategorier og ikke et tal. Sensorerne kan skelne "fuld", "halv" og
/// "for kort" — de kan ikke afgøre om noget var 73 % dybt, og så skal grænsefladen heller
/// ikke påstå det.
enum RepQuality: String, Codable, CaseIterable {
    case full       // talt med, fuld bevægelse
    case partial    // talt med, men kort
    case low        // talt med, men tydeligt utilstrækkelig

    var isGood: Bool { self == .full }
}

struct Rep: Identifiable, Codable {
    var id = UUID()
    var index: Int
    var quality: RepQuality
    /// Den dominerende fejl, hvis der var en. nil når repen var ren.
    var fault: String?
}

struct WorkoutSet: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var reps: [Rep]
    /// Sekunder på vej ned. Tilden i grænsefladen er ikke pynt — grænsen mellem ned og op
    /// er et skøn, og tallet skal se ud som det skøn det er.
    var eccentric: Double
    var concentric: Double
    var duration: TimeInterval

    var total: Int { reps.count }
    var goodCount: Int { reps.filter(\.quality.isGood).count }

    /// Faldt over halvdelen af sættet igennem? Så skal oversigten holde op med at rose.
    var heldUp: Bool { total > 0 && Double(goodCount) / Double(total) >= 0.5 }

    /// Hvor i sættet formen skred — indekset på den første rep der ikke var ren.
    var brokeAt: Int? { reps.first(where: { !$0.quality.isGood })?.index }

    /// Den ene sætning brugeren læser. Den finder aldrig på en fejl for at fylde plads,
    /// og den tier aldrig om en, der faktisk skete.
    var summarySentence: String {
        guard let broke = brokeAt else { return "Formen holdt hele sættet." }
        let fault = reps.first(where: { !$0.quality.isGood })?.fault
        let remaining = total - broke + 1
        if let fault {
            return "Formen holdt i \(broke - 1) reps, så \(fault)."
        }
        return "Formen holdt i \(broke - 1) reps, så blev de sidste \(remaining) korte."
    }
}

struct FaultTally: Identifiable {
    var id = UUID()
    var name: String
    /// 0-1. Andel af sæt hvor fejlen optrådte.
    var share: Double
}

// MARK: - Prøvedata

/// Foreløbige tal, så grænsefladen kan bygges og bedømmes færdig, før målingerne flytter ind.
enum MockData {

    static var goodSet: WorkoutSet {
        var reps = (1...12).map { Rep(index: $0, quality: .full) }
        reps += [Rep(index: 13, quality: .partial, fault: "blev de sidste to korte"),
                 Rep(index: 14, quality: .partial)]
        return WorkoutSet(date: .now, reps: reps, eccentric: 2.1, concentric: 0.9, duration: 72)
    }

    static var badSet: WorkoutSet {
        var reps = (1...5).map { Rep(index: $0, quality: .full) }
        let tail: [RepQuality] = [.partial, .partial, .low, .partial, .low, .low, .partial, .low, .low]
        for (offset, quality) in tail.enumerated() {
            reps.append(Rep(index: 6 + offset,
                            quality: quality,
                            fault: offset == 0 ? "gled hofterne" : nil))
        }
        return WorkoutSet(date: .now, reps: reps, eccentric: 1.4, concentric: 1.1, duration: 68)
    }

    static let recentSessions: [(day: String, total: Int, good: Int)] = [
        ("I dag", 14, 12),
        ("Mandag", 11, 11),
        ("Lørdag", 13, 6)
    ]

    /// Rene reps pr. session over de seneste uger.
    static let trend: [Int] = [9, 11, 10, 12, 11, 13, 12, 14]

    static let faults: [FaultTally] = [
        FaultTally(name: "Hofterne sank", share: 0.78),
        FaultTally(name: "For kort ned", share: 0.44),
        FaultTally(name: "Studs i bunden", share: 0.19)
    ]

    static let streak = 6
    static let bestStreak = 11
    static let bestClean = 14
    static let weekDelta = 3
}
