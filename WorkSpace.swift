//
//  WorkSpace.swift
//  CS53B-Project
//
//  Created by James Hu on 6/7/16.
//  Copyright © 2016 James Hu. All rights reserved.
//

import UIKit

class WorkSpace: CanvasController {
    
    var letterWidthTotal = 0.0
    var xOffset = 0.0
    var xAccumlate = 0.0
    let fsize = 16.0
    var alphaTexts = [TextShape]()
    var texts = [TextShape]()

    override func setup() {
        
        let letters = "Spring morning marvel. Lovely nameless little hill. On a sea of mist. "
        let fontSizeMin = 1.0;
        var counter = 0
        let spacing = 2.0
        let fsize = 16.0
        var spaceChar = 0.0
        var dip = 0.0


        for item in letters.characters {
            let s = String(item)
            let f = Font(name: "Times New Roman", size: fsize)!
            let t = TextShape(text: s, font: f)!
            t.fillColor = Color(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.75)
   
            if (s == " ") {
                spaceChar = 3.5
            } else {
                spaceChar = 0.0
            }
            
            letterWidthTotal += t.width + spacing + spaceChar

            alphaTexts.append(t)
        }
        
        xOffset = (canvas.width - letterWidthTotal) / 2
        
        for letter in alphaTexts {
    
            if (letter.text == " ") {
                spaceChar = 3.5
            } else {
                spaceChar = 0.0
            }
            
            if (letter.text == "g" || letter.text == "j" || letter.text == "p" || letter.text == "q" || letter.text == "y") {
                dip = 3.5
            } else {
                dip = 0.0
            }

            let newCenter = Point(letter.center.x + xAccumlate + xOffset + spaceChar, (canvas.height - letter.height) / 2 + dip)
            letter.center = newCenter
            xAccumlate += letter.width + spacing + spaceChar
            canvas.add(letter)
       
        }
        

        var vPrevious = Vector()
    
        let tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 2

        canvas.addTapGestureRecognizer { location, state, tap in
            
            self.moveInPlace(self.alphaTexts, drawingtxt: self.texts)

        }
     
        
        canvas.addPinchGestureRecognizer { scale, velocity, state in
   
            if (state == .ended) {
                self.clear()
            }
        
        }
        
        canvas.addPanGestureRecognizer { locations, center, translation, velocity, state in
            
            ShapeLayer.disableActions = true
            
            let newFontSize = fontSizeMin + abs(velocity.x / 50.0) + abs(velocity.y / 50.0)
            let newLetter = String(letters[letters.characters.index(letters.startIndex, offsetBy: counter)])
            let font = Font(name: "Times New Roman", size: newFontSize)!
            let text = TextShape(text: newLetter, font: font)!

            
            if self.texts.isEmpty {
                vPrevious = Vector(text.center)
            } else {
                vPrevious = Vector((self.texts.last?.center)!)
            }
            
            let vCurrent = Vector(center)
            
            let ro = (vCurrent - vPrevious).heading
          //let dist = (vCurrent - vPrevious).magnitude


            text.fillColor = Color(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.75)
            text.center = center
           
            text.transform = Transform.makeRotation(-ro)
   
            self.canvas.add(text)
            self.texts.append(text)
                
            counter += 1
            if (counter > letters.characters.count - 1) {
                counter = 0
            }
        }
    }


    
    func moveInPlace(_ txt: [TextShape], drawingtxt: [TextShape]) {
        
        var count = 0

        ShapeLayer.disableActions = true
    
        for i in 0 ..< drawingtxt.count {
            
            let alpha = txt[count]
           
            let animation = ViewAnimation(duration: random01() * 5.0 + 1.5) { () -> Void in

                drawingtxt[i].center = alpha.center
                drawingtxt[i].transform = Transform.makeRotation(0)
            }

            animation.animate()
            ShapeLayer.disableActions = false
                
            count += 1
            if count == txt.count {
                count = 0
            }
            
        }
    }
    
    
    func clear() {
        
        for item in texts {

            let animation = ViewAnimation(duration: random01() * 3.0 + 1.0) { () -> Void in
                let scale = self.fsize / item.font.pointSize

                item.transform = Transform.makeScale(scale, scale)
            }
            
            animation.addCompletionObserver {
                wait(0.35) {
                    item.removeFromSuperview()
                }

            }
            animation.animate()
        }
    }
}

