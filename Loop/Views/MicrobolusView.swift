//
//  MicrobolusView.swift
//  Loop
//
//  Created by Ivan Valkou on 31.10.2019.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import SwiftUI
import Combine

struct DecimalTextField: View {
    private final class ViewModel: ObservableObject {
        @Published var text = ""
        @Binding var value: Double

        private var cancellable: AnyCancellable!
        private let validCharSet = CharacterSet(charactersIn: "1234567890.,")

        private let valueNumberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            return formatter
        }()

        init(value: Binding<Double>) {
            self._value = value
            text = valueNumberFormatter.string(from: value.wrappedValue)!
            cancellable = $text
                .receive(on: DispatchQueue.main)
                .sink { val in
                    if val.rangeOfCharacter(from: self.validCharSet.inverted) == nil {
                        if let value = self.valueNumberFormatter.number(from: self.text)?.doubleValue {
                            self.value = value
                        }
                    } else {
                        self.text = String(self.text.unicodeScalars.filter {
                            self.validCharSet.contains($0)
                        })
                    }
                    if self.text.isEmpty {
                        self.value = 0
                    }
            }
        }
    }

    let placeholder: String

    @ObservedObject private var viewModel: ViewModel

    init(placeholder: String, value: Binding<Double>) {
        self.placeholder = placeholder
        self.viewModel = ViewModel(value: value)
    }

    var body: some View {
        TextField(placeholder, text: $viewModel.text)
            .keyboardType(.numberPad)
    }
}

struct MicrobolusView: View {
    @State var isMicrobolusesWithCOB = false
    @State var isMicrobolusesWithoutCOB = false
    @State var value = 50.0

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle (isOn: $isMicrobolusesWithCOB) {
                        Text("Enable with COB")
                    }

                    DecimalTextField(placeholder: "Size", value: $value)

                }

                Section {
                    Toggle (isOn: $isMicrobolusesWithoutCOB) {
                        Text("\(value)")
                    }

                }

            }
            .navigationBarTitle("Microboluses")
        }

    }
}

struct MicrobolusView_Previews: PreviewProvider {
    static var previews: some View {
        MicrobolusView().environment(\.colorScheme, .dark)
    }
}
