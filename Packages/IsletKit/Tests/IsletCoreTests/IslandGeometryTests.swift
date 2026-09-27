import CoreGraphics
import Testing
@testable import IsletCore

struct IslandGeometryTests {
    let layout = IslandLayout(notch: NotchMetrics(width: 188, height: 32, centerX: 756, isHardware: true))

    @Test(arguments: [IslandState.collapsed, .peek, .expanded])
    func pathFillsItsShapeExactly(state: IslandState) {
        let shape = layout.shape(for: state)
        let box = IslandPath.make(shape, centerX: 300).boundingBoxOfPath
        #expect(abs(box.minX - (300 - shape.outerWidth / 2)) < 0.001)
        #expect(abs(box.width - shape.outerWidth) < 0.001)
        #expect(abs(box.minY) < 0.001)
        #expect(abs(box.height - shape.height) < 0.001)
    }

    @Test func everyStateMorphsWithTheSameSegments() {
        func segments(_ state: IslandState) -> [CGPathElementType] {
            var types: [CGPathElementType] = []
            IslandPath.make(layout.shape(for: state), centerX: 0).applyWithBlock { types.append($0.pointee.type) }
            return types
        }
        #expect(segments(.collapsed) == segments(.expanded))
        #expect(segments(.peek) == segments(.expanded))
    }

    @Test func extremeRadiiStayInsideTheBody() {
        let tiny = IslandShape(width: 20, height: 10, earRadius: 40, cornerRadius: 90)
        let box = IslandPath.make(tiny, centerX: 0).boundingBoxOfPath
        #expect(box.height <= 10.001)
        #expect(box.maxY >= 9.999)
    }

    @Test func statesGrowInOrder() {
        let sizes = [IslandState.collapsed, .peek, .expanded].map { layout.shape(for: $0) }
        #expect(sizes[0].width < sizes[1].width && sizes[1].width < sizes[2].width)
        #expect(sizes[0].height < sizes[1].height && sizes[1].height < sizes[2].height)
    }

    @Test func collapsedWindowHugsTheNotch() {
        let size = layout.windowSize(for: .collapsed)
        #expect(size.height == 32)
        #expect(size.width == CGFloat(188 + 8))
    }

    @Test func canvasHoldsEveryStateAndTheContent() {
        let canvas = CGRect(origin: .zero, size: layout.canvasSize)
        for state in [IslandState.collapsed, .peek, .expanded] {
            #expect(canvas.contains(layout.frame(for: state)))
        }
        #expect(layout.frame(for: .expanded).contains(layout.contentFrame))
        #expect(layout.contentFrame.minY > 32)
    }

    @Test func wideNotchesStillLeaveRoomAroundTheCamera() {
        let wide = IslandLayout(notch: NotchMetrics(width: 400, height: 38, centerX: 900, isHardware: true))
        #expect(wide.shape(for: .expanded).width == 560)
    }
}
