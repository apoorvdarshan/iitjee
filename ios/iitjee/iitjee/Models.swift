import Foundation
import SwiftUI

struct Chapter: Identifiable, Hashable, Sendable {
    let number: Int
    let title: String
    let folderName: String
    let pageCount: Int

    var id: String { folderName }

    var pdfResourceName: String {
        String(format: "%02d", number)
    }

    func pdfURL(for subject: SubjectArea, in bundle: Bundle = .main) -> URL? {
        bundle.url(
            forResource: pdfResourceName,
            withExtension: "pdf",
            subdirectory: "OfflineNotes/\(subject.slug)"
        )
    }

    func readingProgressKey(for subject: SubjectArea) -> String {
        "reader.\(subject.slug).\(number).page"
    }
}

enum SubjectArea: String, CaseIterable, Identifiable, Hashable, Sendable {
    case physics
    case chemistry
    case mathematics

    var id: String { rawValue }
    var slug: String { rawValue }

    var name: String {
        switch self {
        case .physics: "Physics"
        case .chemistry: "Chemistry"
        case .mathematics: "Mathematics"
        }
    }

    var tabName: String {
        self == .mathematics ? "Maths" : name
    }

    var symbol: String {
        switch self {
        case .physics: "atom"
        case .chemistry: "flask.fill"
        case .mathematics: "function"
        }
    }

    var accent: Color {
        switch self {
        case .physics: AppPalette.physics
        case .chemistry: AppPalette.chemistry
        case .mathematics: AppPalette.mathematics
        }
    }

    var secondaryAccent: Color {
        switch self {
        case .physics: AppPalette.physicsSecondary
        case .chemistry: AppPalette.chemistrySecondary
        case .mathematics: AppPalette.mathematicsSecondary
        }
    }

    var tagline: String {
        switch self {
        case .physics: "Build intuition from vectors to modern physics."
        case .chemistry: "Revise physical, organic, and inorganic chemistry."
        case .mathematics: "Move from fundamentals to calculus and 3D geometry."
        }
    }

    var chapters: [Chapter] {
        switch self {
        case .physics: ChapterCatalog.physics
        case .chemistry: ChapterCatalog.chemistry
        case .mathematics: ChapterCatalog.mathematics
        }
    }

    var pageCount: Int {
        chapters.reduce(0) { $0 + $1.pageCount }
    }
}

enum ChapterCatalog {
    static let physics: [Chapter] = [
        Chapter(number: 1, title: "Vectors", folderName: "1.Vectors", pageCount: 9),
        Chapter(number: 2, title: "Unit, Dimension, Measurement, Error", folderName: "2.Unit, Dimension, Measurement, Error", pageCount: 14),
        Chapter(number: 3, title: "Kinematics", folderName: "3.Kinematics", pageCount: 19),
        Chapter(number: 4, title: "Newton's Laws of Motion", folderName: "4.Newton's Laws of Motion", pageCount: 15),
        Chapter(number: 5, title: "Work, Power & Energy", folderName: "5.Work, Power & Energy", pageCount: 19),
        Chapter(number: 6, title: "Conservation of Momentum", folderName: "6.Conservation of Momentum", pageCount: 25),
        Chapter(number: 7, title: "Rotational Motion", folderName: "7.Rotational Motion", pageCount: 36),
        Chapter(number: 8, title: "Gravitation", folderName: "8.Gravitation", pageCount: 16),
        Chapter(number: 9, title: "Fluids & Elasticity", folderName: "9.Fluids & Elasticity", pageCount: 32),
        Chapter(number: 10, title: "Heat & Thermodynamics", folderName: "10.Heat & Thermodynamics", pageCount: 45),
        Chapter(number: 11, title: "Simple Harmonic Motion", folderName: "11.Simple Harmonic Motion", pageCount: 14),
        Chapter(number: 12, title: "Waves & Sound", folderName: "12.Waves & Sound", pageCount: 18),
        Chapter(number: 13, title: "Electrostatics & Current Electricity", folderName: "13.Electrostatics & Current Electricity", pageCount: 92),
        Chapter(number: 14, title: "Magnetics", folderName: "14.Magnetics", pageCount: 30),
        Chapter(number: 15, title: "Permanent Magnet", folderName: "15.Permanent Magnet", pageCount: 9),
        Chapter(number: 16, title: "Electromagnetic Induction", folderName: "16.Electromagnetic Induction", pageCount: 13),
        Chapter(number: 17, title: "Alternating Current", folderName: "17.Alternating Current", pageCount: 14),
        Chapter(number: 18, title: "Electromagnetic Waves", folderName: "18.Electromagnetic Waves", pageCount: 6),
        Chapter(number: 19, title: "Optics", folderName: "19.Optics", pageCount: 45),
        Chapter(number: 20, title: "Modern Physics", folderName: "20.Modern Physics", pageCount: 27),
        Chapter(number: 21, title: "Communication System", folderName: "21.Communication System", pageCount: 9),
        Chapter(number: 22, title: "Semiconductor", folderName: "22.Semiconductor", pageCount: 13),
        Chapter(number: 23, title: "Experimental Skills in Physics", folderName: "23.EXPERIMENTAL SKILLS IN PHYSICS", pageCount: 19),
    ]

    static let chemistry: [Chapter] = [
        Chapter(number: 1, title: "Some Basic Concepts of Chemistry", folderName: "1.Some Basic Concepts of Chemistry", pageCount: 81),
        Chapter(number: 2, title: "Structure of Atom", folderName: "2.Structure of Atom", pageCount: 54),
        Chapter(number: 3, title: "Classification of Elements & Periodicity in Properties", folderName: "3.Classification of Elements & Periodicity in Properties", pageCount: 39),
        Chapter(number: 4, title: "Chemical Bonding & Molecular Structure", folderName: "4.Chemical Bonding & Molecular Structure", pageCount: 86),
        Chapter(number: 5, title: "Gaseous State", folderName: "5.Gaseous State", pageCount: 42),
        Chapter(number: 6, title: "Thermodynamics", folderName: "6.Thermodynamics", pageCount: 54),
        Chapter(number: 7, title: "Chemical Kinetics & Nuclear Chemistry", folderName: "7.Chemical Kinetics & Nuclear Chemistry", pageCount: 24),
        Chapter(number: 8, title: "Hydrogen", folderName: "8.Hydrogen", pageCount: 9),
        Chapter(number: 9, title: "Chemical Equilibrium", folderName: "9.Chemical Equilibrium", pageCount: 20),
        Chapter(number: 10, title: "Ionic Equilibrium", folderName: "10.Ionic Equilibrium", pageCount: 46),
        Chapter(number: 11, title: "The s-BLOCK Elements", folderName: "11.The s-BLOCK elements", pageCount: 24),
        Chapter(number: 12, title: "The p-BLOCK Elements", folderName: "12.The p-BLOCK elements", pageCount: 54),
        Chapter(number: 13, title: "GOC", folderName: "13.GOC", pageCount: 26),
        Chapter(number: 14, title: "Isomerism", folderName: "14.Isomerism", pageCount: 26),
        Chapter(number: 15, title: "Hydrocarbons", folderName: "15.Hydrocarbons", pageCount: 41),
        Chapter(number: 16, title: "Environmental Chemistry", folderName: "16.Environmental Chemistry", pageCount: 17),
        Chapter(number: 17, title: "Electrophilic Aromatic Substitution", folderName: "17.Electrophilic Aromatic Substitution", pageCount: 3),
        Chapter(number: 18, title: "Alkyl & Aryl Halides", folderName: "18.Alkyl & Aryl Halides", pageCount: 14),
        Chapter(number: 19, title: "Alcohol, Phenol & Ether", folderName: "19.Alcohol, Phenol & Ether", pageCount: 27),
        Chapter(number: 20, title: "Aldehydes & Ketones", folderName: "20.Aldehydes & Ketones", pageCount: 27),
        Chapter(number: 21, title: "Carboxylic Acids & Derivatives", folderName: "21.Carboxylic Acids & Derivatives", pageCount: 13),
        Chapter(number: 22, title: "Amines", folderName: "22.Amines", pageCount: 16),
        Chapter(number: 23, title: "Solid State", folderName: "23.Solid State", pageCount: 44),
        Chapter(number: 24, title: "Solutions", folderName: "24.Solutions", pageCount: 17),
        Chapter(number: 25, title: "Surface Chemistry", folderName: "25.Surface Chemistry", pageCount: 19),
        Chapter(number: 26, title: "General Principles and Processes of Isolation of Elements", folderName: "26.General Principles and Processes of Isolation of Elements", pageCount: 14),
        Chapter(number: 27, title: "Electrochemistry", folderName: "27.Electrochemistry", pageCount: 21),
        Chapter(number: 28, title: "The d- and f-BLOCK Elements", folderName: "28.The d- and f- BLOCK Elements", pageCount: 21),
        Chapter(number: 29, title: "Coordination Compounds", folderName: "29.Coordination Compounds", pageCount: 19),
        Chapter(number: 30, title: "Qualitative Salt Analysis", folderName: "30.QUALITATIVE SALT ANALYSIS", pageCount: 24),
        Chapter(number: 31, title: "Polymers", folderName: "31.Polymers", pageCount: 10),
        Chapter(number: 32, title: "Biomolecules", folderName: "32.Biomolecules", pageCount: 25),
        Chapter(number: 33, title: "Chemistry in Everyday Life", folderName: "33.Chemistry in Everyday Life", pageCount: 7),
        Chapter(number: 34, title: "IUPAC Nomenclature", folderName: "34.IUPAC Nomenclature", pageCount: 17),
        Chapter(number: 35, title: "Practical Organic Chemistry", folderName: "35.PRACTICAL ORGANIC CHEMISTRY", pageCount: 4),
        Chapter(number: 36, title: "Purification and Characteristics of Organic Compounds", folderName: "36.Purification and Characteristics of Organic Compounds", pageCount: 7),
        Chapter(number: 37, title: "Conformers", folderName: "37.CONFORMERS", pageCount: 1),
    ]

    static let mathematics: [Chapter] = [
        Chapter(number: 1, title: "Set, Relation & Function", folderName: "1.Set, Relation & Function", pageCount: 58),
        Chapter(number: 2, title: "Linear Inequalities & Linear Programming", folderName: "2.Linear Inequalities & Linear Programming", pageCount: 1),
        Chapter(number: 3, title: "Logarithm", folderName: "3.Logarithm", pageCount: 8),
        Chapter(number: 4, title: "Trigonometric Ratios & Identities", folderName: "4.Trigonometric Ratios & Identities", pageCount: 11),
        Chapter(number: 5, title: "Basic Calculus", folderName: "5.Basic Calculus", pageCount: 38),
        Chapter(number: 6, title: "Quadratic Equations & Expressions", folderName: "6.Quadratic Equations & Expressions", pageCount: 15),
        Chapter(number: 7, title: "Mathematical Reasoning", folderName: "7.Mathematical Reasoning", pageCount: 3),
        Chapter(number: 8, title: "Sequence & Progression", folderName: "8.Sequence & Progression", pageCount: 28),
        Chapter(number: 9, title: "Straight Lines", folderName: "9.Straight Lines", pageCount: 24),
        Chapter(number: 10, title: "Circle", folderName: "10.Circle", pageCount: 20),
        Chapter(number: 11, title: "Parabola & Conic Section", folderName: "11.Parabola & Conic Section", pageCount: 16),
        Chapter(number: 12, title: "Mathematical Induction", folderName: "12.Mathematical Induction", pageCount: 2),
        Chapter(number: 13, title: "Ellipse", folderName: "13.Ellipse", pageCount: 15),
        Chapter(number: 14, title: "Hyperbola", folderName: "14.Hyperbola", pageCount: 9),
        Chapter(number: 15, title: "Complex Number", folderName: "15.Complex Number", pageCount: 16),
        Chapter(number: 16, title: "Solution of Triangle", folderName: "16.Solution of Triangle", pageCount: 13),
        Chapter(number: 17, title: "Trigonometric Equations", folderName: "17.Trigonometric Equations", pageCount: 12),
        Chapter(number: 18, title: "Permutation & Combinations", folderName: "18.Permutation & Combinations", pageCount: 18),
        Chapter(number: 19, title: "Binomial Theorem", folderName: "19.Binomial Theorem", pageCount: 14),
        Chapter(number: 20, title: "Probability", folderName: "20.Probability", pageCount: 12),
        Chapter(number: 21, title: "Statistics", folderName: "21.Statistics", pageCount: 7),
        Chapter(number: 22, title: "Function-II", folderName: "22.Function-II", pageCount: 50),
        Chapter(number: 23, title: "Inverse Trigonometric Functions", folderName: "23.Inverse Trigonometric Functions", pageCount: 22),
        Chapter(number: 24, title: "Limit, Continuity & Differentiability", folderName: "24.Limit, Continuity & Differentiability (Differentiation)", pageCount: 65),
        Chapter(number: 25, title: "Application of Derivatives", folderName: "25.Application of Derivatives", pageCount: 49),
        Chapter(number: 26, title: "Indefinite Integration", folderName: "26.Indefinite Integration", pageCount: 19),
        Chapter(number: 27, title: "Definite Integration", folderName: "27.Definite Integration", pageCount: 16),
        Chapter(number: 28, title: "Area Under Curve (Quadrature)", folderName: "28.Area Under Curve (Quadrature)", pageCount: 6),
        Chapter(number: 29, title: "Differential Equations", folderName: "29.Differential Equations", pageCount: 15),
        Chapter(number: 30, title: "Matrices & Determinants", folderName: "30.Matrices & Determinants", pageCount: 29),
        Chapter(number: 31, title: "Vectors & 3D", folderName: "31.Vectors & 3D", pageCount: 30),
    ]

    static let totalChapterCount = physics.count + chemistry.count + mathematics.count
    static let totalPageCount = [physics, chemistry, mathematics]
        .flatMap { $0 }
        .reduce(0) { $0 + $1.pageCount }
}
