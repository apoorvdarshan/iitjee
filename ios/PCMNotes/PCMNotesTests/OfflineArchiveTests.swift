import Foundation
import PDFKit
import Testing
@testable import PCMNotes

/// The build tool turns the repository's handwritten JPEGs into one PDF per chapter
/// (BuildTools/GenerateOfflineNotes.swift). These tests read the real app bundle,
/// so the catalog the app shows can never drift from the notes it ships.
@MainActor
struct OfflineArchiveTests {
    private struct Manifest: Decodable {
        struct Subject: Decodable {
            let slug: String
            let chapters: Int
            let pages: Int
        }

        let formatVersion: Int
        let chapterCount: Int
        let pageCount: Int
        let subjects: [Subject]
    }

    @Test func everyChapterOpensAsABundledPDFWithItsPageCount() throws {
        for subject in SubjectArea.allCases {
            for chapter in subject.chapters {
                let url = try #require(
                    chapter.pdfURL(for: subject),
                    "\(subject.name) chapter \(chapter.number) has no bundled PDF"
                )
                let document = try #require(PDFDocument(url: url), "\(url.lastPathComponent) is not a PDF")
                #expect(
                    document.pageCount == chapter.pageCount,
                    "\(subject.name) \(chapter.number) \(chapter.title): PDF has \(document.pageCount) pages"
                )
            }
        }
    }

    @Test func bundleHoldsExactlyTheCatalogChapters() throws {
        let root = try #require(Bundle.main.resourceURL?.appendingPathComponent("OfflineNotes"))
        for subject in SubjectArea.allCases {
            let files = try FileManager.default.contentsOfDirectory(
                atPath: root.appendingPathComponent(subject.slug).path
            )
            #expect(
                Set(files) == Set(subject.chapters.map { "\($0.pdfResourceName).pdf" }),
                "\(subject.name) PDFs in the bundle differ from the chapter catalog"
            )
        }
    }

    @Test func manifestTotalsMatchTheCatalog() throws {
        let url = try #require(
            Bundle.main.url(forResource: "manifest", withExtension: "json", subdirectory: "OfflineNotes")
        )
        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: url))

        #expect(manifest.formatVersion == 1)
        #expect(manifest.chapterCount == ChapterCatalog.totalChapterCount)
        #expect(manifest.pageCount == ChapterCatalog.totalPageCount)
        #expect(manifest.subjects.map(\.slug) == SubjectArea.allCases.map(\.slug))
        for (entry, subject) in zip(manifest.subjects, SubjectArea.allCases) {
            #expect(entry.chapters == subject.chapters.count, "\(subject.name) chapters")
            #expect(entry.pages == subject.pageCount, "\(subject.name) pages")
        }
    }

    @Test func folderNamesStartWithTheirChapterNumber() {
        // The build tool numbers each PDF from the digits before the folder's first dot.
        for subject in SubjectArea.allCases {
            for chapter in subject.chapters {
                #expect(
                    chapter.folderName.hasPrefix("\(chapter.number)."),
                    "\(chapter.folderName) does not start with \(chapter.number)."
                )
                #expect(chapter.id == chapter.folderName)
            }
        }
    }
}
