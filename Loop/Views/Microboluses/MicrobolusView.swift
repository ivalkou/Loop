//
//  MicrobolusView.swift
//  Loop
//
//  Created by Ivan Valkou on 31.10.2019.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopCore
import HealthKit
import Combine

struct MicrobolusView: View {
    @ObservedObject var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            switchSection
            partialApplicationSection
            basalRateSection
            temporaryOverridesSection
            safetySection
            otherOptionsSection
            if !viewModel.events.isEmpty {
                lastEventSection
            }
        }
        .navigationBarTitle("Microboluses")
        .modifier(AdaptsToSoftwareKeyboard())
    }

    private var switchSection: some View {
        Section {
            Toggle (isOn: $viewModel.microbolusesWithCOB) {
                Text("Enable With Carbs")
            }

            Toggle (isOn: $viewModel.microbolusesWithoutCOB) {
                Text("Enable Without Carbs")
            }
        }
    }

    private var partialApplicationSection: some View {
        Section(footer:
            Text("What part of the recommended bolus will be applied automatically.")
        ) {
            Picker(selection: $viewModel.partialApplicationIndex, label: Text("Partial Bolus Application")) {
                ForEach(0 ..< viewModel.partialApplicationValues.count) { index in
                    Text(String(format: "%.0f %%", self.viewModel.partialApplicationValues[index] * 100)).tag(index)
                }
            }
        }
    }

    private var temporaryOverridesSection: some View {
        Section(header: Text("Temporary overrides").font(.headline)) {
            Toggle (isOn: $viewModel.disableByOverride) {
                Text("Disable MB by enabling temporary override")
            }

            VStack(alignment: .leading) {
                Text("If the override's target range starts at the given value or more").font(.caption)
                HStack {
                    TextField("0", text: $viewModel.lowerBound)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(height: 38)

                    Text(viewModel.unit.localizedShortUnitString)
                }
            }
        }
    }

    private var otherOptionsSection: some View {
        Section(header: Text("Other Options").font(.headline), footer:
            Text("This is the minimum microbolus size in units that will be delivered. Only if the microbolus calculated is equal to or greater than this number of units will a bolus be delivered.")
        ) {
            Toggle (isOn: $viewModel.openBolusScreen) {
                Text("Open bolus screen after carbs on watch")
            }

            Picker(selection: $viewModel.pickerMinimumBolusSizeIndex, label: Text("Minimum Bolus Size")) {
                ForEach(0 ..< viewModel.minimumBolusSizeValues.count) { index in Text(String(format: "%.2f U", self.viewModel.minimumBolusSizeValues[index])).tag(index)
                }
            }
        }
    }

    private var safetySection: some View {
        Section(header: Text("Safety").font(.headline), footer:
            Text("Sometimes you may see an exclamation mark next to the glucose value. In such cases microboluses will not be applied. Turn this setting on if you want to ignore warnings.")
        ) {
            Toggle (isOn: $viewModel.allowWhenGlucoseBelowTarget) {
                Text("Allow MBs when glucose is below target range")
            }
            Toggle (isOn: $viewModel.enabledWhenSensorStateIsInvalid) {
                Text("Allow MBs when the sensor value is invalid")
            }
        }
    }

    private var basalRateSection: some View {
        Section(footer:
            Text("Limits the maximum basal rate to a multiple of the scheduled basal rate in loop. The value cannot exceed your maximum basal rate setting. This setting is ignored if microboluses are disabled.")
        ) {
            Picker(selection: $viewModel.basalRateMultiplierIndex, label: Text("Basal Rate Multiplier")) {
                ForEach(0 ..< viewModel.basalRateMultiplierValues.count) { index in
                    if self.viewModel.basalRateMultiplierValues[index] > 0 {
                        Text("× " + self.viewModel.formatter.string(from: self.viewModel.basalRateMultiplierValues[index])!).tag(index)
                    } else {
                        Text("Max basal limit").tag(index)
                    }
                }
            }
        }
    }

    private var lastEventSection: some View {
        Section(header: Text("Last Event").font(.headline)) {
            NavigationLink(
                destination: List(viewModel.events.reversed()) {
                    Text($0.description)
                }
            ) {
                Text(viewModel.events.last?.description ?? "No event")
            }

        }
    }
}

struct MicrobolusView_Previews: PreviewProvider {
    static var previews: some View {
        MicrobolusView(viewModel: .init(
            settings: Microbolus.Settings(),
            glucoseUnit: HKUnit(from: "mmol/L")
            )
        )
            .environment(\.colorScheme, .dark)
            .previewLayout(.fixed(width: 375, height: 1000))
    }
}

// MARK: - Helpers

struct AdaptsToSoftwareKeyboard: ViewModifier {
    @State var currentHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(.bottom, currentHeight).animation(.easeOut(duration: 0.25))
            .edgesIgnoringSafeArea(currentHeight == 0 ? Edge.Set() : .bottom)
            .onAppear(perform: subscribeToKeyboardChanges)
    }

    private let keyboardHeightOnOpening = NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillShowNotification)
        .map { $0.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect }
        .map { $0.height }


    private let keyboardHeightOnHiding = NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillHideNotification)
        .map {_ in return CGFloat(0) }

    private func subscribeToKeyboardChanges() {
        _ = Publishers.Merge(keyboardHeightOnOpening, keyboardHeightOnHiding)
            .subscribe(on: DispatchQueue.main)
            .sink { height in
                if self.currentHeight == 0 || height == 0 {
                    self.currentHeight = height
                }
        }
    }
}
