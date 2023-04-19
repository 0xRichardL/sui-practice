module game::table_lib {
  use sui::object::{Self, UID};
  use std::vector;
  use sui::hash;
  use sui::tx_context::{Self, TxContext};

  struct CardBox has key, store {
    id: UID,
    cards: vector<u8>,
  }

  struct Holder has store {
    playerAddr: address,
    cards: vector<u8>,
    bet: u64,
  }

  public fun unbox(ctx: &mut TxContext): CardBox {
    let cards = vector::empty<u8>();
    let i = 1;
    while (i <= 52) {
      vector::push_back(&mut cards, i % 13);
    };

    return CardBox {
      id: object::new(ctx),
      cards,
    }
  }

  public fun pick(box: &mut CardBox, holder: &mut Holder, num: u8, ctx: &mut TxContext) {
    while(num > 0) {
      let totalCards = vector::length<u8>(&box.cards);
      let seed = totalCards + tx_context::epoch_timestamp_ms(ctx);
      let rd = rand((totalCards as u8), seed);
      let cardValue = vector::borrow<u8>(&box.cards, (rd as u64));
      vector::push_back<u8>(&mut holder.cards, *cardValue);
      vector::swap<u8>(&mut box.cards, (rd as u64), totalCards - 1);
      num = num - 1;
    }
  }

  public fun new_holder(bet: u64, ctx: &mut TxContext): Holder {
    Holder {
      playerAddr: tx_context::sender(ctx),
      cards: vector::empty<u8>(),
      bet,
    }
  }

  public fun borrow_cards(holder: &Holder): &vector<u8> {
    &holder.cards
  }

  public fun borrow_player_addr(holder: &Holder): address {
    holder.playerAddr
  }

  fun rand(max: u8, seed: u64): u8 {
    let seedArr = vector::empty<u8>();
    vector::push_back<u8>(&mut seedArr, ((seed >> 8) as u8));
    vector::push_back<u8>(&mut seedArr, ((seed >> 16) as u8));
    vector::push_back<u8>(&mut seedArr, ((seed >> 24) as u8));
    let randArr = hash::keccak256(&seedArr);
    let first = vector::borrow<u8>(&randArr, 0); 
    return *first % max
  }
}