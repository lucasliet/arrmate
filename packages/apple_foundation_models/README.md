# apple_foundation_models

Local Flutter plugin that exposes Apple's
[Foundation Models](https://developer.apple.com/documentation/foundationmodels)
framework — the on-device language model behind Apple Intelligence — on iOS
and macOS.

- `availability()` reports whether the model can be used and, when it cannot,
  why (device not eligible, Apple Intelligence turned off, model still
  downloading, OS older than iOS 26 / macOS 26).
- `respond()` answers a prompt in a fresh session that follows the given
  instructions. Callers own the conversation history and must keep the
  instructions, prompt and response within the model's 4,096-token context.

The Swift sources compile with SDKs that predate the framework
(`#if canImport(FoundationModels)`) and every use is gated behind
`@available(iOS 26.0, macOS 26.0, *)`, so the app keeps running on older
systems and reports the model as unavailable there. Other platforms have no
native implementation and also report it as unavailable.
