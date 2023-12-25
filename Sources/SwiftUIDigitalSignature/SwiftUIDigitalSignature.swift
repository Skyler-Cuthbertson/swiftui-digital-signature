
//
//  SignatureView.swift
//  SwiftUI Recipes
//
//  Created by Gordan Glavaš on 28.06.2021..
//

import SwiftUI
import CoreGraphics
import UIKit

private let fontFamlies = ["Zapfino", "SavoyeLetPlain", "SnellRoundhand", "SnellRoundhand-Black"]
private let bigFontSize: CGFloat = 44
private let placeholderText = "Signature"
private let maxHeight: CGFloat = 160
private let lineWidth: CGFloat = 5

public struct SignatureView: View {
    public let onSave: (UIImage) -> Void
    
    @State private var saveSignature = false
    
    @State private var fontFamily = fontFamlies[0]
    @State private var color = Color.gray
    
    @State private var drawing = DrawingPath()
    @State private var image = UIImage()
    @State private var isImageSet = false
    @State private var text = ""
    
    public init(onSave: @escaping (UIImage) -> Void) {
        self.onSave = onSave
    }
    
    public var body: some View {
        VStack {
            self.signatureContent
            HStack {
                Spacer()

                HStack {
                    Spacer()
                    Button { clear()} label: { Image(systemName: "trash.fill").tint(.red) }
                    Spacer()
                }
                .padding()
                .background(.gray)
                .clipShape(.rect(cornerRadius: 15))
                .padding()
                
                Spacer()

                HStack {
                    Spacer()
                    Button { clear()} label: { Image(systemName: "checkmark.shield.fill").tint(.green) }
                    Spacer()
                }
                .padding()
                .background(.teal)
                .clipShape(.rect(cornerRadius: 15))
                .padding()
                
                Spacer()
                
            } // h both
            HStack {
                ColorPickerCompat(selection: $color)
            }
            Spacer()
        }.padding()
    }
    
    private var signatureContent: some View {
        return Group {
            SignatureDrawView(drawing: $drawing, fontFamily: $fontFamily, color: $color)
            
        }.padding(.vertical)
    }
    
    private func extractImageAndHandle() {
        let image: UIImage
        let path = drawing.cgPath
        let maxX = drawing.points.map { $0.x }.max() ?? 0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: maxX, height: maxHeight))
        let uiImage = renderer.image { ctx in
            ctx.cgContext.setStrokeColor(color.uiColor.cgColor)
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

struct ColorPickerCompat: View {
    @Binding var selection: Color
    
    @State private var showPopover = false
    private let availableColors: [Color] = [.blue, .black, .red]
    
    var body: some View {
        if #available(iOS 14.0, *) {
            ColorPicker(selection: $selection) {
                EmptyView()
            }
        } else {
            Button(action: {
                showPopover.toggle()
            }, label: {
                colorCircle(selection)
            }).popover(isPresented: $showPopover) {
                ForEach(availableColors, id: \.self) { color in
                    Button(action: {
                        selection = color
                        showPopover.toggle()
                    }, label: {
                        colorCircle(color)
                    })
                }
            }
        }
    }
    
    private func colorCircle(_ color: Color) -> some View {
        Circle()
            .foregroundColor(color)
            .frame(width: 32, height: 32)
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
  @Binding var fontFamily: String
  @Binding var color: Color
  
  @State private var drawingBounds: CGRect = .zero
    
    var body: some View {
      ZStack {
        Color.white
          .background(GeometryReader { geometry in
            Color.clear.preference(key: FramePreferenceKey.self,
                                   value: geometry.frame(in: .local))
          })
          .onPreferenceChange(FramePreferenceKey.self) { bounds in
            drawingBounds = bounds
          }
        if drawing.isEmpty {
          Image(systemName: "signature")
        } else {
          DrawShape(drawingPath: drawing)
            .stroke(lineWidth: lineWidth)
            .foregroundColor(color)
        }
      }
      .frame(height: maxHeight)
      .gesture(DragGesture(minimumDistance: 0.001)
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
  }
}

struct DrawingPath {
    private(set) var points = [CGPoint]()
    private var breaks = [Int]()
    
    var isEmpty: Bool {
        points.isEmpty
    }
    
    mutating func addPoint(_ point: CGPoint) {
        if let lastPoint = points.last, !breaks.contains(points.count) {
            let diffX = point.x - lastPoint.x
            let diffY = point.y - lastPoint.y
            let distance = hypot(diffX, diffY)
            let numberOfPoints = max(1, Int(distance / 2.0)) // adjust the divider to change the number of intermediate points
            for i in 1...numberOfPoints {
                let t = CGFloat(i) / CGFloat(numberOfPoints)
                let x = lastPoint.x + (diffX * t)
                let y = lastPoint.y + (diffY * t)
                points.append(CGPoint(x: x, y: y))
            }
        } else {
            points.append(point)
        }
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


