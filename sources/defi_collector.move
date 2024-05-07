module defi_collector::defi_collector {
    use std::vector;
    use sui::transfer;
    use sui::sui::SUI;
    use std::string::String;
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use sui::object::{Self, ID, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};

    // Errors
    const INSUFFICIENT_BALANCE: u64 = 1;
    const NOT_COMPANY: u64 = 2;
    const NOT_USER: u64 = 4;
    const NOT_COMPANY_USER: u64 = 5;
    const INSUFFICIENT_CAPACITY: u64 = 6;

    // Structs
    struct Company has key, store {
        id: UID,
        name: String,
        email: String,
        phone: String,
        charges: u64,
        balance: Balance<SUI>,
        collections: Table<ID, Collection>,
        requests: Table<ID, CollectionRequest>,
        company_address: address,
    }

    struct Collection has key, store {
        id: UID,
        user_address: address,
        user_name: String,
        truck_id: ID,
        date: String,
        time: u64,
        district: String,
        weight: u64,
        charges: u64, // Added to store charges for the collection
    }

    struct User has key, store {
        id: UID,
        name: String,
        email: String,
        home_address: String,
        balance: Balance<SUI>,
        user_address: address,
    }

    struct Truck has key, store {
        id: UID,
        registration: String,
        driver_name: String,
        capacity: u64,
        total_capacity: u64, // Added to store the total capacity
        district: String,
        assigned_users: vector<address>,
    }

    struct CollectionRequest has key, store {
        id: UID,
        user_address: address,
        home_address: String,
        created_at: u64,
    }

    // Functions
    // Create new company
    public entry fun create_company(
        name: String,
        email: String,
        phone: String,
        charges: u64,
        ctx: &mut TxContext
    ) {
        // Add authentication or access control mechanisms
        let company_id = object::new(ctx);
        let company = Company {
            id: company_id,
            name,
            email,
            phone,
            charges,
            balance: balance::zero<SUI>(),
            collections: table::new<ID, Collection>(ctx),
            requests: table::new<ID, CollectionRequest>(ctx),
            company_address: tx_context::sender(ctx),
        };
        transfer::share_object(company);
    }

    // Create new user and collection request
    public entry fun create_user_and_request(
        name: String,
        email: String,
        home_address: String,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Add authentication or access control mechanisms
        let user_id = object::new(ctx);
        let user = User {
            id: user_id,
            name,
            email,
            home_address,
            balance: balance::zero<SUI>(),
            user_address: tx_context::sender(ctx),
        };
        transfer::share_object(user);

        let request_id = object::new(ctx);
        let request = CollectionRequest {
            id: request_id,
            user_address: tx_context::sender(ctx),
            home_address,
            created_at: clock::timestamp_ms(clock),
        };
        transfer::share_object(request);
    }

    // Add truck
    public entry fun add_truck(
        registration: String,
        driver_name: String,
        capacity: u64,
        district: String,
        ctx: &mut TxContext
    ) {
        // Add authentication or checks for authorized entities
        let truck_id = object::new(ctx);
        let truck = Truck {
            id: truck_id,
            registration,
            driver_name,
            capacity,
            total_capacity: capacity, // Initialized with the same value as capacity
            district,
            assigned_users: vector::empty<address>(),
        };
        transfer::share_object(truck);
    }

    // Add collection
    public entry fun add_collection(
        company: &mut Company,
        user: &mut User,
        truck: &mut Truck,
        date: String,
        district: String,
        weight: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == company.company_address, NOT_COMPANY);
        assert!(user.user_address == object::uid_to_address(&user.id), NOT_COMPANY_USER);
        let collection_id = object::new(ctx);
        let truck_id = &truck.id;
        let collection = Collection {
            id: collection_id,
            user_address: user.user_address,
            user_name: user.name,
            truck_id: object::uid_to_inner(truck_id),
            date,
            time: clock::timestamp_ms(clock),
            district,
            weight,
            charges: company.charges, // Storing charges in the Collection struct
        };

        // Deduct charges from user balance
        assert!(balance::value(&user.balance) >= company.charges, INSUFFICIENT_BALANCE);
        assert!(weight <= truck.capacity, INSUFFICIENT_CAPACITY);

        let charges = coin::take(&mut user.balance, company.charges, ctx);
        transfer::public_transfer(charges, company.company_address);

        // Update truck capacity
        truck.capacity = truck.capacity - weight;

        table::add<ID, Collection>(&mut company.collections, object::uid_to_inner(&collection.id), collection);
    }

    // Fund account
    public entry fun fund_account(
        account: &mut User or &mut Company,
        amount: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let account_address = if let User { user_address, .. } = account {
            assert!(tx_context::sender(ctx) == user_address, NOT_USER);
            user_address
        } else if let Company { company_address, .. } = account {
            assert!(tx_context::sender(ctx) == company_address, NOT_COMPANY);
            company_address
        } else {
            abort 0 // Or handle the case when the account is neither User nor Company
        };

        let coin_amount = coin::into_balance(amount);
        if let User { balance, .. } = account {
            balance::join(&mut account.balance, coin_amount);
        } else if let Company { balance, .. } = account {
            balance::join(&mut account.balance, coin_amount);
        };
    }

    // Check account balance
    public fun check_balance<T: key + store>(
        account: &T,
        ctx: &mut TxContext
    ): &Balance<SUI> {
        let account_address = if let User { user_address, .. } = account {
            assert!(tx_context::sender(ctx) == user_address, NOT_USER);
            user_address
        } else if let Company { company_address, .. } = account {
            assert!(tx_context::sender(ctx) == company_address, NOT_COMPANY);
            company_address
        } else {
            abort 0 // Or handle the case when the account is neither User nor Company
        };

        if let User { balance, .. } = account {
            &account.balance
        } else if let Company { balance, .. } = account {
            &account.balance
        } else {
            abort 0 // Or handle the case when the account is neither User nor Company
        }
    }

    // Withdraw from account
    public entry fun withdraw_from_account<T: key + store>(
        account: &mut T,
        amount: u64, ctx: &mut TxContext
    ) {
        let account_address = if let User { user_address, .. } = account {
            assert!(tx_context::sender(ctx) == user_address, NOT_USER);
            user_address
        } else if let Company { company_address, .. } = account {
            assert!(tx_context::sender(ctx) == company_address, NOT_COMPANY);
            company_address
        } else {
            abort 0 // Or handle the case when the account is neither User nor Company
        };

        if let User { balance, .. } = account {
            assert!(balance::value(&balance) >= amount, INSUFFICIENT_BALANCE);
            let payment = coin::take(&mut balance, amount, ctx);
            transfer::public_transfer(payment, account_address);
        } else if let Company { balance, .. } = account {
            assert!(balance::value(&balance) >= amount, INSUFFICIENT_BALANCE);
            let payment = coin::take(&mut balance, amount, ctx);
            transfer::public_transfer(payment, account_address);
        };
    }
}
