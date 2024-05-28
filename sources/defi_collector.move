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
  use sui::event;
  // Errors
  const EInsufficientBalance: u64 = 1;
  const ENotCompany: u64 = 2;
  const ENotUser: u64 = 4;
  const ENotCompanyUser: u64 = 5;
  const EInsufficientCapacity: u64 = 6;
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
    company: address,
  }
  struct Collection has key, store {
    id: UID,
    user: address,
    userName: String,
    truckId: ID,
    date: String,
    time: u64,
    district: String,
    weight: u64,
  }
  struct User has key, store {
    id: UID,
    name: String,
    email: String,
    homeAddress: String,
    balance: Balance<SUI>,
    user: address,
  }
  struct Truck has key, store {
    id: UID,
    registration: String,
    driverName: String,
    capacity: u64,
    district: String,
    assignedUsers: vector<address>,
  }
  struct CollectionRequest has key, store {
    id: UID,
    user: address,
    homeAddress: String,
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
      company: tx_context::sender(ctx),
    };
    transfer::share_object(company);
  }
  // Create new user
  public entry fun create_user(
    name: String,
    email: String,
    homeAddress: String,
    ctx: &mut TxContext
  ) {
    let user_id = object::new(ctx);
    let user = User {
      id: user_id,
      name,
      email,
      homeAddress,
      balance: balance::zero<SUI>(),
      user: tx_context::sender(ctx),
    };
    transfer::share_object(user);
  }
  // Add truck
  public entry fun add_truck(
    registration: String,
    driverName: String,
    capacity: u64,
    district: String,
    ctx: &mut TxContext
  ) {
    let truck_id = object::new(ctx);
    let truck = Truck {
      id: truck_id,
      registration,
      driverName,
      capacity,
      district,
      assignedUsers: vector::empty<address>(),
    };
    transfer::share_object(truck);
  }
  // New collection request
  public entry fun new_collection_request(
    user: &User,
    clock: &Clock,
    ctx: &mut TxContext
  ){
    assert!(tx_context::sender(ctx) == user.user, ENotUser);
    let request_id = object::new(ctx);
    let request = CollectionRequest {
      id: request_id,
      user: user.user,
      homeAddress: user.homeAddress,
      created_at: clock::timestamp_ms(clock),
    };
    table::add(&mut table::borrow_mut(&mut company.requests), object::uid_to_inner(&request.id), request);
    transfer::share_object(request);
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
  ){
    assert!(tx_context::sender(ctx) == company.company, ENotCompany);
    assert!(user.user == tx_context::sender(ctx), ENotCompanyUser);
    assert!(balance::value(&user.balance) >= company.charges, EInsufficientBalance);
    assert!(weight <= truck.capacity, EInsufficientCapacity);
    let collection_id = object::new(ctx);
    let collection = Collection {
      id: collection_id,
      user: user.user,
      userName: user.name,
      truckId: object::uid_to_inner(&truck.id),
      date,
      time: clock::timestamp_ms(clock),
      district,
      weight,
    };
    // Deduct charges from user balance
    let charges = coin::take(&mut user.balance, company.charges, ctx);
    balance::join(&mut company.balance, charges);
    // Reduce truck capacity by weight
    truck.capacity = truck.capacity - weight;
    table::add(&mut table::borrow_mut(&mut company.collections), object::uid_to_inner(&collection.id), collection);
  }
  // Fund user account
  public entry fun fund_user_account(
    user: &mut User,
    amount: Coin<SUI>,
    ctx: &mut TxContext
  ) {
    assert!(tx_context::sender(ctx) == user.user, ENotUser);
    let coin_amount = coin::into_balance(amount);
    balance::join(&mut user.balance, coin_amount);
  }
  // Check user balance
  public fun user_check_balance(
    user: &User,
    ctx: &mut TxContext
  ): &Balance<SUI> {
    assert!(tx_context::sender(ctx) == user.user, ENotUser);
    &user.balance
  }
  // Company check balance
  public fun company_check_balance(
    company: &Company,
    ctx: &mut TxContext
  ): &Balance<SUI> {
    assert!(tx_context::sender(ctx) == company.company, ENotCompany);
    &company.balance
  }
  // Withdraw company balance
  public entry fun withdraw_company_balance(
    company: &mut Company,
    amount: u64,
    ctx: &mut TxContext
  ) {
    assert!(tx_context::sender(ctx) == company.company, ENotCompany);
    assert!(balance::value(&company.balance) >= amount, EInsufficientBalance);
    let payment = coin::take(&mut company.balance, amount, ctx);
    transfer::public_transfer(payment, company.company);
  }
  // Reassign users to different trucks
  public entry fun reassign_users(
    truck: &mut Truck,
    new_truck: &mut Truck,
    user_addresses: vector<address>,
    ctx: &mut TxContext
  ) {
    assert!(tx_context::sender(ctx) == object::uid_to_address(&truck.id), ENotCompany);
    assert!(tx_context::sender(ctx) == object::uid_to_address(&new_truck.id), ENotCompany);
    for user_address in user_addresses {
      assert!(vector::contains(&truck.assignedUsers, &user_address), ENotUser);
      vector::remove(&mut truck.assignedUsers, &user_address);
      vector::push_back(&mut new_truck.assignedUsers, user_address);
    }
  }
  // Cancel collection request
  public entry fun cancel_collection_request(
    company: &mut Company,
    request_id: ID,
    ctx: &mut TxContext
  ) {
    assert!(tx_context::sender(ctx) == company.company, ENotCompany);
    table::remove(&mut table::borrow_mut(&mut company.requests), request_id);
  }
  // Event emission for logging important actions
  public fun emit_event(msg: String, ctx: &mut TxContext) {
    event::emit(msg, ctx);
  }
}