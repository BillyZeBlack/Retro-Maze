# Premium Setup

## Product placeholders

- `APP_STORE_CONNECT_PRODUCT_ID_PLACEHOLDER`
- `APP_STORE_CONNECT_REFERENCE_NAME_PLACEHOLDER`
- `APP_STORE_CONNECT_DISPLAY_NAME_FR_PLACEHOLDER`
- `APP_STORE_CONNECT_DISPLAY_NAME_EN_PLACEHOLDER`
- `APP_STORE_CONNECT_DESCRIPTION_FR_PLACEHOLDER`
- `APP_STORE_CONNECT_DESCRIPTION_EN_PLACEHOLDER`
- `APP_STORE_CONNECT_PRICE_PLACEHOLDER`

## Review and metadata placeholders

- `APP_STORE_CONNECT_REVIEW_SCREENSHOT_PLACEHOLDER`
- `APP_STORE_CONNECT_REVIEW_NOTES_PLACEHOLDER`
- `APP_STORE_SUPPORT_URL_PLACEHOLDER`
- `APP_STORE_PRIVACY_POLICY_URL_PLACEHOLDER`
- `APP_STORE_COPYRIGHT_PLACEHOLDER`
- `APP_STORE_PROMOTIONAL_TEXT_PLACEHOLDER`

## Files to update

- Product identifier in [PremiumManager.swift](/Users/wills/Downloads/Retro Maze/Snail Maze Like2/Model/PremiumManager.swift)
- Local StoreKit config in [Premium.storekit](/Users/wills/Downloads/Retro Maze/Snail Maze Like2/Configuration/Premium.storekit)

## Manual Xcode steps

1. Open the scheme editor for the app target.
2. In `Run` > `Options`, attach `Snail Maze Like2/Configuration/Premium.storekit` as the StoreKit configuration file.
3. Run the app from Xcode and test purchase and restore flows locally.

## Manual App Store Connect steps

1. Create a non-consumable in-app purchase with `APP_STORE_CONNECT_PRODUCT_ID_PLACEHOLDER` or replace that placeholder everywhere with the real product ID.
2. Fill the localized names, descriptions, price, review screenshot, and review notes using the placeholders above.
3. Submit the in-app purchase with the app version that exposes the premium sheet and StoreKit 2 flow.

## Expected runtime behavior

- Authority for premium access comes from StoreKit transactions, not from a local boolean.
- `Transaction.currentEntitlements` restores premium status on launch.
- `AppStore.sync()` is used for manual restoration.
- The local `.storekit` file is only for Xcode local testing.
