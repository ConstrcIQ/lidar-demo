import CoreGraphics
import Foundation

/// Én person fulgt over tid. Hver person har sin egen vinke-analyse, så to mennesker
/// i billedet ikke blander deres håndbevægelser sammen.
final class TrackedPerson {
    let id: Int
    let analyzer = WaveAnalyzer()
    var pose: BodyPose
    var verdict = WaveVerdict()
    var lastSeen: TimeInterval

    init(id: Int, pose: BodyPose, time: TimeInterval) {
        self.id = id
        self.pose = pose
        self.lastSeen = time
    }
}

/// Holder styr på hvem der er hvem fra billede til billede.
///
/// Metoden er bevidst simpel: hver ny skikkelse knyttes til den nærmeste kendte person,
/// hvis de står tæt nok på hinanden. Det holder til to-tre personer der bevæger sig
/// almindeligt. Går to mennesker forbi hinanden tæt på, kan identiteterne bytte plads —
/// det kræver en rigtig sporingsalgoritme at undgå, og det er ikke det denne demo handler om.
final class PersonTracker {

    /// Hvor langt en person må flytte sig mellem to billeder og stadig regnes for den samme.
    /// Målt i Vision-enheder, hvor 1,0 er hele billedets bredde.
    private let maximumMatchDistance: CGFloat = 0.2
    /// Hvor længe en person må være forsvundet, før vi glemmer hende.
    private let forgetAfter: TimeInterval = 1.0

    private var people: [TrackedPerson] = []
    private var nextId = 1

    /// Knytter dette billedes skikkelser til de kendte personer og returnerer dem alle.
    func update(poses: [BodyPose], time: TimeInterval) -> [TrackedPerson] {
        var unmatched = people
        var result: [TrackedPerson] = []

        for pose in poses {
            let centre = pose.centre

            // Find den nærmeste endnu ikke-parrede person inden for rækkevidde.
            var bestIndex: Int?
            var bestDistance = maximumMatchDistance
            for (index, candidate) in unmatched.enumerated() {
                let other = candidate.pose.centre
                let distance = hypot(centre.x - other.x, centre.y - other.y)
                if distance < bestDistance {
                    bestDistance = distance
                    bestIndex = index
                }
            }

            if let bestIndex {
                let person = unmatched.remove(at: bestIndex)
                person.pose = pose
                person.lastSeen = time
                result.append(person)
            } else {
                let person = TrackedPerson(id: nextId, pose: pose, time: time)
                nextId += 1
                result.append(person)
            }
        }

        // Personer vi ikke så denne gang beholdes et øjeblik — folk forsvinder konstant
        // for et enkelt billede, når en arm dækker for skulderen.
        let stillRecent = unmatched.filter { time - $0.lastSeen < forgetAfter }
        people = result + stillRecent
        return result
    }

    func reset() {
        people.removeAll()
        nextId = 1
    }
}
