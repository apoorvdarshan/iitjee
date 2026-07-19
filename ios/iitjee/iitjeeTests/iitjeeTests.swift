//
//  iitjeeTests.swift
//  iitjeeTests
//
//  Created by Apoorv Darshan on 20/07/26.
//

import Foundation
import Testing
@testable import iitjee

struct iitjeeTests {

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

    @Test func noteURLsEncodeFolderNamesAsPathSegments() {
        let chapter = ChapterCatalog.physics[4]
        let url = chapter.pageURL(for: .physics, page: 1)

        #expect(url.scheme == "https")
        #expect(url.host == "iitjee.apoorvdarshan.com")
        #expect(!url.absoluteString.contains(" "))
        #expect(url.absoluteString.hasSuffix("0001.jpg"))
    }
}
