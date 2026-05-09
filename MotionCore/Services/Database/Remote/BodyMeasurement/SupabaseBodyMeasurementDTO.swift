//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Database / Remote / BodyMeasurement                  /
// Datei . . . . : SupabaseBodyMeasurementDTO.swift                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Encodable-DTO für Körpermaß-Messungen (Supabase Full-Backup)   /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : CodingKeys MÜSSEN alle Felder explizit listen — sonst fehlen     /
//                nil-Optionals still im Payload (CodingKeys deaktiviert             /
//                convertToSnakeCase vollständig).                                  /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct SupabaseBodyMeasurementDTO: Encodable {
    let id:                      UUID
    let date:                    Date
    let notes:                   String
    let bodyWeight:              Double?
    let chestCircumference:      Double?
    let waistCircumference:      Double?
    let abdomenCircumference:    Double?
    let hipCircumference:        Double?
    let armCircumferenceLeft:    Double?
    let armCircumferenceRight:   Double?
    let thighCircumferenceLeft:  Double?
    let thighCircumferenceRight: Double?
    let updatedAt:               Date

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case notes
        case bodyWeight              = "body_weight"
        case chestCircumference      = "chest_circumference"
        case waistCircumference      = "waist_circumference"
        case abdomenCircumference    = "abdomen_circumference"
        case hipCircumference        = "hip_circumference"
        case armCircumferenceLeft    = "arm_circumference_left"
        case armCircumferenceRight   = "arm_circumference_right"
        case thighCircumferenceLeft  = "thigh_circumference_left"
        case thighCircumferenceRight = "thigh_circumference_right"
        case updatedAt               = "updated_at"
    }
}
