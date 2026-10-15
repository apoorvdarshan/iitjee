import Testing
@testable import PCMNotes

/// The reader's Previous/Next controls, slider and page counter.
@MainActor
struct ReaderPaginationTests {
    private func page(_ current: Int, of count: Int, spread: Bool = false) -> ReaderPagination {
        ReaderPagination(currentPage: current, pageCount: count, spreadMode: spread)
    }

    /// Counter labels seen while pressing Next from the first page, then Previous back.
    private func walk(pages count: Int, spread: Bool) -> (forward: [String], backward: [String]) {
        var pagination = page(1, of: count, spread: spread)
        var forward = [pagination.counterLabel]
        while pagination.canGoForward {
            pagination.currentPage = pagination.nextPage
            forward.append(pagination.counterLabel)
        }
        var backward = [pagination.counterLabel]
        while pagination.canGoBack {
            pagination.currentPage = pagination.previousPage
            backward.append(pagination.counterLabel)
        }
        return (forward, backward)
    }

    @Test func continuousReadingStepsOnePageAndStopsAtTheEnds() {
        let first = page(1, of: 9)
        #expect(!first.canGoBack)
        #expect(first.canGoForward)
        #expect(first.nextPage == 2)

        let last = page(9, of: 9)
        #expect(last.canGoBack)
        #expect(!last.canGoForward)
        #expect(last.previousPage == 8)

        let (forward, backward) = walk(pages: 4, spread: false)
        #expect(forward == ["1 / 4", "2 / 4", "3 / 4", "4 / 4"])
        #expect(backward == forward.reversed())
    }

    @Test func spreadShowsTheFirstPageAloneThenPairs() {
        let (forward, backward) = walk(pages: 9, spread: true)
        #expect(forward == ["1 / 9", "2–3 / 9", "4–5 / 9", "6–7 / 9", "8–9 / 9"])
        #expect(backward == forward.reversed())
    }

    @Test func spreadWithAnEvenPageCountEndsOnTheLastPageAlone() {
        var pagination = page(1, of: 10, spread: true)
        var starts = [pagination.currentPage]
        while pagination.canGoForward {
            pagination.currentPage = pagination.nextPage
            starts.append(pagination.currentPage)
        }
        #expect(starts == [1, 2, 4, 6, 8, 10])
        #expect(pagination.spreadStart == 10)
        #expect(pagination.lastSpreadStart == 10)
    }

    @Test func pageInsideASpreadMovesByWholeSpreads() {
        let third = page(3, of: 9, spread: true)
        #expect(third.spreadStart == 2)
        #expect(third.nextPage == 4)
        #expect(third.previousPage == 1)
        #expect(page(5, of: 9, spread: true).previousPage == 2)
        #expect(page(8, of: 9, spread: true).nextPage == 9)
        #expect(!page(9, of: 9, spread: true).canGoForward, "page 9 is in the last spread (8–9)")
    }

    @Test func spokenPositionNamesEveryVisiblePage() {
        #expect(page(5, of: 9).positionLabel == "Page 5 of 9")
        #expect(page(1, of: 9, spread: true).positionLabel == "Page 1 of 9")
        #expect(page(3, of: 9, spread: true).positionLabel == "Pages 2 through 3 of 9")
        #expect(page(3, of: 9, spread: true).counterLabel == "2–3 / 9")
    }

    @Test func singlePageChapterCannotMove() {
        for spread in [false, true] {
            let only = page(1, of: 1, spread: spread)
            #expect(!only.canGoBack)
            #expect(!only.canGoForward)
            #expect(only.counterLabel == "1 / 1")
        }
    }

    @Test func sliderPositionsSnapToPagesWithinTheChapter() {
        let pagination = page(1, of: 9)
        #expect(pagination.page(forSliderValue: 4.4) == 4)
        #expect(pagination.page(forSliderValue: 4.5) == 5)
        #expect(pagination.page(forSliderValue: 0) == 1)
        #expect(pagination.page(forSliderValue: 12) == 9)
        // Before the PDF reports its pages the slider still stays on page 1.
        #expect(page(1, of: 0).page(forSliderValue: 3) == 1)
    }
}
