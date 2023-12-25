
//
//  SignatureView.swift
//  SwiftUI Recipes
//
//  Created by Gordan Glavaš on 28.06.2021..
//

import SwiftUI
import CoreGraphics
import UIKit

private let maxHeight: CGFloat = 160
private let lineWidth: CGFloat = 3

public struct SignatureView: View {
    public let onSave: (UIImage) -> Void
    
    @State private var saveSignature = false
        
    @State private var drawing = DrawingPath()
    @State private var image = UIImage()
    @State private var isImageSet = false
    @State private var text = ""
    
    public init(onSave: @escaping (UIImage) -> Void) {
        self.onSave = onSave
    }
    
    public var body: some View {
        VStack {
            SignatureDrawView(drawing: $drawing)
            
            Text("Please Sign").font(.caption).fontWeight(.medium)
            
            HStack {
                Spacer()
                
                HStack {
                    Spacer()
                    Button { clear()} label: { Text("Clear").fontWeight(.semibold).foregroundStyle(.white) }
                    Spacer()
                }
                .padding()
                .background(.gray)
                .clipShape(.rect(cornerRadius: 10))
                .padding()
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button { onSave(self.image)} label: { Text("Done").fontWeight(.semibold).foregroundStyle(.white) }
                    Spacer()
                }
                .padding()
                .background(.mint)
                .clipShape(.rect(cornerRadius: 10))
                .padding()
                
                Spacer()
                
            } // h both
        }
        .padding()
    }
    

    
    private func extractImageAndHandle() {
        let image: UIImage
        let path = drawing.cgPath
        let maxX = drawing.points.map { $0.x }.max() ?? 0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: maxX, height: maxHeight))
        let uiImage = renderer.image { ctx in
            ctx.cgContext.setStrokeColor(CGColor(red: 255, green: 255, blue: 255, alpha: 1.0)) // white
            ctx.cgContext.setLineWidth(lineWidth)
            ctx.cgContext.beginPath()
            ctx.cgContext.addPath(path)
            ctx.cgContext.drawPath(using: .stroke)
        }
        image = uiImage
        
        if saveSignature {
            if let data = image.pngData(),
               let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let filename = docsDir.appendingPathComponent("Signature-\(Date()).png")
                try? data.write(to: filename)
            }
        }
        onSave(image)
    }
    
    private func clear() {
        drawing = DrawingPath()
        image = UIImage()
        isImageSet = false
        text = ""
    }
    
    
}


struct FramePreferenceKey: PreferenceKey {
  static var defaultValue: CGRect = .zero

  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    value = nextValue()
  }
}


struct SignatureDrawView: View {
    @Binding var drawing: DrawingPath
    
    @State private var drawingBounds: CGRect = .zero
    
    var body: some View {
        VStack {
            ZStack {
                Color.clear
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: FramePreferenceKey.self,
                                               value: geometry.frame(in: .local))
                    })
                    .onPreferenceChange(FramePreferenceKey.self) { bounds in
                        drawingBounds = bounds
                    }
                
                if drawing.isEmpty {
                    Image(systemName: "signature")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    DrawShape(drawingPath: drawing)
                        .stroke(lineWidth: lineWidth)
                        .foregroundStyle(.white)
                }
            } // z
            .frame(height: maxHeight)
            .gesture(DragGesture(minimumDistance: 0.0001)
                .onChanged( { value in
                    if drawingBounds.contains(value.location) {
                        drawing.addPoint(value.location)
                    } else {
                        drawing.addBreak()
                    }
                }).onEnded( { value in
                    drawing.addBreak()
                }))
            .overlay(RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray))
            
            HStack {
                Image(systemName: "xmark")
                VStack {
                    Divider()
                        .frame(height: 2)
                        .overlay(.white)
                }
            }
        } // v
    }
}

struct DrawingPath {
    private(set) var points = [CGPoint]()
    private var breaks = [Int]()
    
    var isEmpty: Bool {
        points.isEmpty
    }
    
    mutating func addPoint(_ point: CGPoint) {
        points.append(point)
    }
    
    
    mutating func addBreak() {
        breaks.append(points.count)
    }
    
    var cgPath: CGPath {
        let path = CGMutablePath()
        guard let firstPoint = points.first else { return path }
        path.move(to: firstPoint)
        for i in 1..<points.count {
            if breaks.contains(i) {
                path.move(to: points[i])
            } else {
                path.addLine(to: points[i])
            }
            
        }
        return path
    }
    
    var path: Path {
        var path = Path()
        guard let firstPoint = points.first else { return path }
        path.move(to: firstPoint)
        for i in 1..<points.count {
            if breaks.contains(i) {
                path.move(to: points[i])
            } else {
                path.addLine(to: points[i])
            }
            
        }
        return path
    }
}

struct DrawShape: Shape {
    let drawingPath: DrawingPath
    
    func path(in rect: CGRect) -> Path {
        drawingPath.path
    }
}




extension Color {
    var uiColor: UIColor {
        if #available(iOS 14, *) {
            return UIColor(self)
        } else {
            let components = self.components
            return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
        }
    }
    
    private var components: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
        let result = scanner.scanHexInt64(&hexNumber)
        if result {
            r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000ff) / 255
        }
        return (r, g, b, a)
    }
}


