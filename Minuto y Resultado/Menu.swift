//
//  Menu.swift
//  90 Min
//
//  Created by Victor Manuel Del Rio Garcia on 12/10/22.
//

import SwiftUI

struct MenuSettings: View {
    @Binding var gdprSettings:Bool
    var body: some View {
       
    }
    
}

struct Menu_Previews: PreviewProvider {
    static var previews: some View {
        MenuSettings(gdprSettings: .constant(false))
    }
}
