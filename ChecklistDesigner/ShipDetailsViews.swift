import SwiftUI

struct ShipParticularsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var shipDetails: ShipDetailsManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text("Ship Particulars")
                        .viewTitleStyle()
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                Divider()
                    .background(.white.opacity(0.3))
            }
            .background(Color(red: 0.1, green: 0.1, blue: 0.2))
            
            List {
                Section {
                    TextField("Ship Name", text: Binding(
                        get: { shipDetails.shipParticulars.shipName },
                        set: { newValue in
                            shipDetails.updateParticulars { $0.shipName = newValue }
                        }
                    ))
                    .disabled(shipDetails.shipParticulars.isLocked)
                    
                    TextField("IMO Number", text: Binding(
                        get: { shipDetails.shipParticulars.imoNumber },
                        set: { newValue in
                            shipDetails.updateParticulars { $0.imoNumber = newValue }
                        }
                    ))
                    .disabled(shipDetails.shipParticulars.isLocked)
                    
                    TextField("Call Sign", text: Binding(
                        get: { shipDetails.shipParticulars.callSign },
                        set: { newValue in
                            shipDetails.updateParticulars { $0.callSign = newValue }
                        }
                    ))
                    .disabled(shipDetails.shipParticulars.isLocked)
                    
                    TextField("Flag", text: Binding(
                        get: { shipDetails.shipParticulars.flag },
                        set: { newValue in
                            shipDetails.updateParticulars { $0.flag = newValue }
                        }
                    ))
                    .disabled(shipDetails.shipParticulars.isLocked)
                    
                    TextField("Ship Type", text: Binding(
                        get: { shipDetails.shipParticulars.shipType },
                        set: { newValue in
                            shipDetails.updateParticulars { $0.shipType = newValue }
                        }
                    ))
                    .disabled(shipDetails.shipParticulars.isLocked)
                }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        shipDetails.toggleParticularsLock()
                    }) {
                        Image(systemName: shipDetails.shipParticulars.isLocked ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(shipDetails.shipParticulars.isLocked ? .gray : .blue)
                    }
                }
            }
        }
    }
} 