//
//  PCMNotesTests.swift
//  PCMNotesTests
//
//  Created by Apoorv Darshan on 20/07/26.
//

import Foundation
import Testing
@testable import PCMNotes

struct PCMNotesTests {

    @Test func catalogMatchesTheArchive() {
        #expect(SubjectArea.physics.chapters.count == 23)
        #expect(SubjectArea.physics.pageCount == 539)
        #expect(SubjectArea.chemistry.chapters.count == 37)
        #expect(SubjectArea.chemistry.pageCount == 993)
        #expect(SubjectArea.mathematics.chapters.count == 31)
        #expect(SubjectArea.mathematics.pageCount == 641)
        #expect(ChapterCatalog.totalChapterCount == 91)
        #expect(ChapterCatalog.totalPageCount == 2_173)
    }

    @Test func chapterNumbersAreContinuous() {
        for subject in SubjectArea.allCases {
            #expect(subject.chapters.map(\.number) == Array(1...subject.chapters.count))
            #expect(subject.chapters.allSatisfy { $0.pageCount > 0 })
        }
    }

    @Test func chapterPDFResourcesHaveStableLocalNames() {
        let chapter = ChapterCatalog.physics[4]

        #expect(chapter.pdfResourceName == "05")
        #expect(chapter.readingProgressKey(for: .physics) == "reader.physics.5.page")
    }

    @Test func everyChapterMapsToOneUniquePDF() {
        for subject in SubjectArea.allCases {
            let resourceNames = subject.chapters.map(\.pdfResourceName)

            #expect(Set(resourceNames).count == subject.chapters.count)
            #expect(resourceNames.first == "01")
            #expect(resourceNames.last == String(format: "%02d", subject.chapters.count))
        }
    }

    @Test func tipProductsUseStableOrderedIdentifiers() {
        #expect(
            TipProductID.allCases.map(\.rawValue) == [
                "com.apoorvdarshan.iitjee.tip.small",
                "com.apoorvdarshan.iitjee.tip.medium",
                "com.apoorvdarshan.iitjee.tip.large",
                "com.apoorvdarshan.iitjee.tip.generous"
            ]
        )
        #expect(Set(TipProductID.allCases.map(\.rawValue)).count == 4)
    }
}
