//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
//----------------------------------------------------------------------------------/
// Abschnitt . . : UI-Beispiele                                                     /
// Datei . . . . : GlassButtonExamples.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.12.2025                                                       /
// Beschreibung  : Beispiele für die Verwendung des GlassFloatingButton Modifiers   /
//----------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
//----------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Verwendungsbeispiele

struct GlassButtonExamples: View {
    var body: some View {
        VStack(spacing: 40) {
            
            // BEISPIEL 1: Standard Floating Action Button
            Button {
                print("Standard Button")
            } label: {
                IconType(icon: .system("plus"), color: .blue, size: 24)
                    .glassButton(size: 60, accentColor: .blue)
            }
            
            // BEISPIEL 2: Kleinerer Button mit anderer Farbe
            Button {
                print("Kleiner Button")
            } label: {
                IconType(icon: .system("heart.fill"), color: .red, size: 16)
                    .glassButton(size: 44, accentColor: .red)
            }
            
            // BEISPIEL 3: Großer Button
            Button {
                print("Großer Button")
            } label: {
                IconType(icon: .system("play.fill"), color: .green, size: 32)
                    .glassButton(size: 80, accentColor: .green)
            }
            
            // BEISPIEL 4: Button mit Asset-Icon
            Button {
                print("Asset Button")
            } label: {
                IconType(icon: .asset("dein-icon"), color: .purple, size: 24)
                    .glassButton(size: 60, accentColor: .purple)
            }
            
            // BEISPIEL 5: Reihe von Buttons
            HStack(spacing: 20) {
                Button {
                    print("Edit")
                } label: {
                    IconType(icon: .system("pencil"), color: .orange, size: 18)
                        .glassButton(size: 50, accentColor: .orange)
                }
                
                Button {
                    print("Delete")
                } label: {
                    IconType(icon: .system("trash"), color: .red, size: 18)
                        .glassButton(size: 50, accentColor: .red)
                }
                
                Button {
                    print("Share")
                } label: {
                    IconType(icon: .system("square.and.arrow.up"), color: .blue, size: 18)
                        .glassButton(size: 50, accentColor: .blue)
                }
            }
        }
        .padding()
    }
}

// MARK: - Verwendung in echten Views

/*
 
 BEISPIEL: In einer Liste mit Inline-Buttons
 
 ForEach(items) { item in
     HStack {
         Text(item.name)
         Spacer()
         
         Button {
             editItem(item)
         } label: {
             IconType(icon: .system("pencil"), color: .blue, size: 14)
                 .glassFloatingButton(size: 36, accentColor: .blue)
         }
     }
 }
 
 
 BEISPIEL: Custom Toolbar Button
 
 .toolbar {
     ToolbarItem(placement: .topBarTrailing) {
         Button {
             showSettings()
         } label: {
             IconType(icon: .system("gearshape.fill"), color: .blue, size: 16)
                 .glassFloatingButton(size: 40, accentColor: .blue)
         }
     }
 }
 
 
 BEISPIEL: Action Buttons in einer Card
 
 VStack {
     // Card Content
     
     HStack(spacing: 16) {
         Button { like() } label: {
             IconType(icon: .system("heart"), color: .red, size: 16)
                 .glassFloatingButton(size: 44, accentColor: .red)
         }
         
         Button { share() } label: {
             IconType(icon: .system("square.and.arrow.up"), color: .blue, size: 16)
                 .glassFloatingButton(size: 44, accentColor: .blue)
         }
         
         Button { bookmark() } label: {
             IconType(icon: .system("bookmark"), color: .orange, size: 16)
                 .glassFloatingButton(size: 44, accentColor: .orange)
         }
     }
 }
 .glassCard()
 
*/

#Preview {
    GlassButtonExamples()
}
