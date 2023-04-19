module game::three_card {
  use std::vector;
  use sui::object::{Self, UID};
  use sui::transfer;
  use sui::coin::{Self, Coin};
  use sui::balance::{Self, Balance};
  use sui::sui::SUI;
  use sui::tx_context::{Self, TxContext};

  use game::table_lib::{Self, CardBox, Holder};

  const ENoPlayerYet: u64 = 1;
  const ENotTheWinner: u64 = 2;

  struct Game has key, store {
    id: UID,
    creater: address,
    cardBox: CardBox,
    holders: vector<Holder>,
    pot: Balance<SUI>,
    winnerIdx: u64,
  }

  public entry fun create_game(ctx: &mut TxContext) {
    transfer::transfer(Game {
      id: object::new(ctx),
      creater: tx_context::sender(ctx),
      cardBox: table_lib::unbox(ctx),
      holders: vector::empty<Holder>(),
      pot: balance::zero<SUI>(),
      winnerIdx: 0,
    }, tx_context::sender(ctx));
  }

  public entry fun bet(game: &mut Game, sui: &mut Coin<SUI>, amount: u64, ctx: &mut TxContext) {
    let player_balance = coin::balance_mut<SUI>(sui);
    let bet_balance = balance::split<SUI>(player_balance, amount);
    balance::join(&mut game.pot, bet_balance);
    let holder = table_lib::new_holder(amount, ctx);
    table_lib::pick(&mut game.cardBox, &mut holder, 3, ctx);
    vector::push_back<Holder>(&mut game.holders, holder);
  }

  public entry fun showOff(game: &mut Game, _ctx: &mut TxContext) {
    assert!(vector::length<Holder>(&game.holders) > 0, ENoPlayerYet);
    let i = 0;
    let max = 0;
    while(i < vector::length<Holder>(&game.holders)) {
      let holder = vector::borrow(&game.holders, i);
      let j = 0;
      let sum = 0;
      let cards = table_lib::borrow_cards(holder);
      while(j < vector::length<u8>(cards)) {
        let cardValue = vector::borrow<u8>(cards, j);
        if (*cardValue > 10) {
          sum = sum + 10;
        } else {
          sum = sum + *cardValue;
        };
        j = j + 1;
      };
      if (sum > max) {
        max = sum;
       game.winnerIdx = i;
      };
      i = i + 1;
    };
  }

  public entry fun withdraw(game: &mut Game, ctx: &mut TxContext) {
    let holder = vector::borrow(&game.holders, game.winnerIdx);
    let sender = tx_context::sender(ctx);
    assert!(sender == table_lib::borrow_player_addr(holder), ENotTheWinner);
    let pride = balance::withdraw_all<SUI>(&mut game.pot);
    let sui = coin::from_balance<SUI>(pride, ctx);
    transfer::public_transfer(sui, sender);
  }
}