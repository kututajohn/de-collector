module data_marketplace::data_marketplace {
    // Imports
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use std::option::{Option, none, some, is_some, contains, borrow};
    use std::vector;
    // Errors
    const EInvalidBid: u64 = 1;
    const EInvalidData: u64 = 2;
    const EDispute: u64 = 3;
    const EAlreadyResolved: u64 = 4;
    const ENotProvider: u64 = 5;
    const EInvalidWithdrawal: u64 = 7;
    // Struct definitions
    struct DataListing has key, store {
        id: UID,
        provider: address,
        consumer: Option<address>,
        description: vector<u8>,
        price: u64,
        escrow: Balance<SUI>,
        dataSubmitted: bool,
        dispute: bool,
        category: vector<u8>, // New field: category
        tags: vector<u8>, // New field: tags
        rating: u32, // New field: rating
        reviews: vector<vector<u8>>, // New field: reviews
    }
    // Accessors
    public entry fun get_listing_description(listing: &DataListing): vector<u8> {
        listing.description
    }
    public entry fun get_listing_price(listing: &DataListing): u64 {
        listing.price
    }
    public entry fun get_listing_category(listing: &DataListing): vector<u8> {
        listing.category
    }
    public entry fun get_listing_tags(listing: &DataListing): vector<u8> {
        listing.tags
    }
    public entry fun get_listing_rating(listing: &DataListing): u32 {
        listing.rating
    }
    public entry fun get_listing_reviews(listing: &DataListing): vector<vector<u8>> {
        listing.reviews
    }
    // Public - Entry functions
    public entry fun create_listing(description: vector<u8>, price: u64, category: vector<u8>, tags: vector<u8>, ctx: &mut TxContext) {
        let listing_id = object::new(ctx);
        transfer::share_object(DataListing {
            id: listing_id,
            provider: tx_context::sender(ctx),
            consumer: none(),
            description: description,
            price: price,
            escrow: balance::zero(),
            dataSubmitted: false,
            dispute: false,
            category: category, // Set category
            tags: tags, // Set tags
            rating: 0, // Initialize rating
            reviews: vector::empty(), // Initialize reviews
        });
    }
    public entry fun bid_on_listing(listing: &mut DataListing, payment: Coin<SUI>, ctx: &mut TxContext) {
        assert!(!is_some(&listing.consumer), EInvalidBid);
        listing.consumer = some(tx_context::sender(ctx));
        let payment_balance = coin::into_balance(payment);
        balance::join(&mut listing.escrow, payment_balance);
    }
    public entry fun submit_data(listing: &mut DataListing, ctx: &mut TxContext) {
        assert!(contains(&listing.consumer, &tx_context::sender(ctx)), EInvalidData);
        listing.dataSubmitted = true;
    }
    public entry fun dispute_listing(listing: &mut DataListing, ctx: &mut TxContext) {
        assert!(listing.provider == tx_context::sender(ctx), EDispute);
        listing.dispute = true;
    }
    public entry fun resolve_dispute(listing: &mut DataListing, resolved: bool, ctx: &mut TxContext) {
        assert!(listing.provider == tx_context::sender(ctx), EDispute);
        assert!(listing.dispute, EAlreadyResolved);
        assert!(is_some(&listing.consumer), EInvalidBid);
        let escrow_amount = balance::value(&listing.escrow);
        let escrow_coin = coin::take(&mut listing.escrow, escrow_amount, ctx);
        if (resolved) {
            let consumer = *borrow(&listing.consumer);
            // Transfer funds to the consumer
            transfer::public_transfer(escrow_coin, consumer);
        } else {
            // Refund funds to the provider
            transfer::public_transfer(escrow_coin, listing.provider);
        };
        // Reset listing state
        listing.consumer = none();
        listing.dataSubmitted = false;
        listing.dispute = false;
    }
    public entry fun release_payment(listing: &mut DataListing, ctx: &mut TxContext) {
        assert!(listing.provider == tx_context::sender(ctx), ENotProvider);
        assert!(listing.dataSubmitted && !listing.dispute, EInvalidData);
        assert!(is_some(&listing.consumer), EInvalidBid);
        let escrow_amount = balance::value(&listing.escrow);
        let escrow_coin = coin::take(&mut listing.escrow, escrow_amount, ctx);
        // Transfer funds to the provider
        transfer::public_transfer(escrow_coin, listing.provider);
        // Reset listing state
        listing.consumer = none();
        listing.dataSubmitted = false;
        listing.dispute = false;
    }
    // Additional functions
    public entry fun cancel_listing(listing: &mut DataListing, ctx: &mut TxContext) {
        assert!(listing.provider == tx_context::sender(ctx) || contains(&listing.consumer, &tx_context::sender(ctx)), ENotProvider);
        // Refund funds to the provider if not yet paid
        if (is_some(&listing.consumer) && !listing.dataSubmitted && !listing.dispute) {
            let escrow_amount = balance::value(&listing.escrow);
            let escrow_coin = coin::take(&mut listing.escrow, escrow_amount, ctx);
            transfer::public_transfer(escrow_coin, listing.provider);
        };
        // Reset listing state
        listing.consumer = none();
        listing.dataSubmitted = false;
        listing.dispute = false;
    }
    public entry fun update_listing_description(listing: &mut DataListing, new_description: vector<u8>, ctx: &mut TxContext) {
        assert!(listing.provider == tx_context::sender(ctx), ENotProvider);
        listing.description = new_description;
    }
    public entry fun update_listing_price(listing: &mut DataListing, new_price: u64, ctx: &mut TxContext) {
        assert!(listing.provider == tx_context::sender(ctx), ENotProvider);
        listing.price = new_price;
    }
    public entry fun add_funds_to_listing(listing: &mut DataListing, amount: Coin<SUI>, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == listing.provider, ENotProvider);
        let added_balance = coin::into_balance(amount);
        balance::join(&mut listing.escrow, added_balance);
    }
    public entry fun request_refund(listing: &mut DataListing, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == listing.provider, ENotProvider);
        assert!(listing.dataSubmitted == false, EInvalidWithdrawal);
        let escrow_amount = balance::value(&listing.escrow);
        let escrow_coin = coin::take(&mut listing.escrow, escrow_amount, ctx);
        // Refund funds to the provider
        transfer::public_transfer(escrow_coin, listing.provider);
        // Reset listing state
        listing.consumer = none();
        listing.dataSubmitted = false;
        listing.dispute = false;
    }
    public entry fun mark_listing_complete(listing: &mut DataListing, ctx: &mut TxContext) {
        assert!(contains(&listing.consumer, &tx_context::sender(ctx)), ENotProvider);
        listing.dataSubmitted = true;
        // Additional logic to mark the listing as complete
    }
    public entry fun update_rating(listing: &mut DataListing, new_rating: u32, ctx: &mut TxContext) {
        assert!(listing.provider == tx_context::sender(ctx), ENotProvider);
        listing.rating = new_rating;
    }
    public entry fun get_listing_info(listing: &DataListing): (vector<u8>, u64, vector<u8>, vector<u8>, u32, vector<vector<u8>>) {
        (listing.description, listing.price, listing.category, listing.tags, listing.rating, listing.reviews)
    }
    public entry fun update_tags(listing: &mut DataListing, new_tags: vector<u8>, ctx: &mut TxContext) {
        assert!(listing.provider == tx_context::sender(ctx), ENotProvider);
        listing.tags = new_tags;
    }
    public entry fun update_category(listing: &mut DataListing, new_category: vector<u8>, ctx: &mut TxContext) {
        assert!(listing.provider == tx_context::sender(ctx), ENotProvider);
        listing.category = new_category;
    }
}