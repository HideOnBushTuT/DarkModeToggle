enum VividToggleArt {
    static let cloudGroups: [CloudGroup] = [
        CloudGroup(
            circles: [
                ArtCircle(x: 96, y: 57, radius: 18),
                ArtCircle(x: 116, y: 49, radius: 19),
                ArtCircle(x: 137, y: 54, radius: 22),
                ArtCircle(x: 157, y: 43, radius: 23),
                ArtCircle(x: 177, y: 53, radius: 25),
                ArtCircle(x: 194, y: 43, radius: 22),
            ],
            opacity: 0.48,
            duration: 4.8
        ),
        CloudGroup(
            circles: [
                ArtCircle(x: 73, y: 75, radius: 25),
                ArtCircle(x: 98, y: 67, radius: 23),
                ArtCircle(x: 122, y: 74, radius: 28),
                ArtCircle(x: 148, y: 64, radius: 26),
                ArtCircle(x: 174, y: 73, radius: 30),
                ArtCircle(x: 198, y: 61, radius: 27),
            ],
            opacity: 1,
            duration: 6.2
        ),
    ]

    static let stars: [ArtStar] = [
        ArtStar(group: 1, x: 27, y: 18, radius: 7.5),
        ArtStar(group: 2, x: 83, y: 45, radius: 7.5),
        ArtStar(group: 3, x: 15, y: 38, radius: 5),
        ArtStar(group: 4, x: 61, y: 35, radius: 5),
        ArtStar(group: 5, x: 72, y: 18, radius: 3),
        ArtStar(group: 6, x: 38, y: 52, radius: 3),
    ]

    static let starDurations: [Int: Double] = [
        1: 3.5,
        2: 4.1,
        3: 4.9,
        4: 5.3,
        5: 3,
        6: 2.2,
    ]
}
