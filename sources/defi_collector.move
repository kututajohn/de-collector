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

  //   errors
  const EInsuficcientBalance: u64 = 1;
  const ENotCompany: u64 = 2;
  const ENotUser: u64 = 4;
  const ENotCompanyUser: u64 = 5;
  const EInsufficientCapacity: u64 = 6;

  //   structs
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

  struct CompanyCap has key {
    id: UID,
    for: ID
  }

  struct Collection has key, store {
    id: UID,
    truck: Truck,
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

  //   functions
  // create new company
  public fun create_company(
    name: String,
    email: String,
    phone: String,
    charges: u64,
    ctx: &mut TxContext
  ) : CompanyCap {
    let id_ = object::new(ctx);
    let inner_ = object::uid_to_inner(&id_);
    let company = Company {
      id: id_,
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

    CompanyCap {
      id: object::new(ctx),
      for: inner_
    }
  }

  // create new user
  public fun create_user(
    name: String,
    email: String,
    homeAddress: String,
    ctx: &mut TxContext
  ) : User {
    let user_id = object::new(ctx);
    User {
      id: user_id,
      name,
      email,
      homeAddress,
      balance: balance::zero<SUI>(),
      user: tx_context::sender(ctx),
    } 
  }

  // add truck
  public fun new_truck(
    registration: String,
    driverName: String,
    capacity: u64,
    district: String,
    ctx: &mut TxContext
  ) : Truck {
    let truck_id = object::new(ctx);
    Truck {
      id: truck_id,
      registration,
      driverName,
      capacity,
      district,
      assignedUsers: vector::empty<address>(),
    }
  }
  
  //   add collection
  public entry fun add_collection(
    company: &mut Company,
    user: &mut User,
    truck: Truck,
    date: String,
    district: String,
    weight: u64,
    clock: &Clock,
    ctx: &mut TxContext
  ){
    assert!(tx_context::sender(ctx) == company.company, ENotCompany);
    assert!(user.user == object::uid_to_address(&user.id), ENotCompanyUser);
    assert!(weight <= truck.capacity, EInsufficientCapacity);
    assert!(balance::value(&user.balance) >= company.charges, EInsuficcientBalance);
    let collection = Collection {
      id:  object::new(ctx),
      truck: truck,
      date,
      time: clock::timestamp_ms(clock),
      district,
      weight,
    };

    let charges = coin::take(&mut user.balance, company.charges, ctx);
    transfer::public_transfer(charges, company.company);

    let payment = coin::take(&mut user.balance, company.charges, ctx);
    coin::put(&mut company.balance, payment);

    table::add<ID, Collection>(&mut company.collections, object::uid_to_inner(&collection.id), collection);
  }

  // fund user account
  public entry fun deposit(
    user: &mut User,
    amount: Coin<SUI>,
  ) {
    let coin_amount = coin::into_balance(amount);
    balance::join(&mut user.balance, coin_amount);
  }

  public fun withdraw(
    user: &mut Company,
    amount: u64,
    ctx: &mut TxContext
  ) : Coin<SUI> {
    let payment = coin::take(&mut user.balance, amount, ctx);
    payment
  }
  // check user balance
  public fun user_check_balance(
    user: &User
  ): u64  {
    balance::value(&user.balance)
  }

  // company check balance
  public fun company_check_balance(
    company: &Company
  ): u64  {
    balance::value(&company.balance)
  }

  // withdraw company balance
  public fun withdraw_company_balance(
    cap: &CompanyCap,
    company: &mut Company,
    amount: u64,
    ctx: &mut TxContext
  ) : Coin<SUI> {
    assert!(cap.for == object::id(company), ENotCompany);
    let payment = coin::take(&mut company.balance, amount, ctx);
    payment
  }
}