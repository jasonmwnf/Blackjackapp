require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do
  def calc_total(cards)
    arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    arr.select{|element| element == "A"}.count.times do
      break if total <= 21
      total -= 10
    end
    
    total

  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end
end

before do
  @display_buttons = true
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/set_username'  
  end
end

get '/set_username' do
  erb :form
end

post '/player_name' do
  if params[:player_name].empty?
    @error = "Name is requried!"
    halt erb(:form)
  end

  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  # deck
  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle!
  # deal cards
    session[:dealer_cards] = []
    session[:player_cards] = []
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    # dealer cards
    # player cards
  erb :game
end

post '/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calc_total(session[:player_cards])
  if player_total == 21
    @success = "#{session[:player_name]}, You've got Blackjack! You Win!"
    @display_buttons = false
  elsif player_total > 21
    @error = "Sorry, it looks like #{session[:player_name]} busted."
    @display_buttons = false
  end
  erb :game
end

post '/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @display_buttons = false
  redirect '/dealer_turn'
end

get '/dealer_turn' do
  @display_buttons = false

  dealer_total = calc_total(session[:dealer_cards])

  if dealer_total == 21
    @error = "Sorry, dealer hit blackjack."
  elsif dealer_total > 21
    @success = "Congrats! Dealer busts. You Win!"
  elsif dealer_total >= 17
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end
      
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/dealer_turn'
end

get '/game/compare' do
  @display_buttons = false
  
  player_total = calc_total(session[:player_cards])
  dealer_total = calc_total(session[:dealer_cards])

  if player_total < dealer_total
    @error = "sorry, dealer wins."
  elsif player_total > dealer_total
    @success = "Congrats, you win!"
  else
    @success = "It's a tie!"
  end

  erb :game
end

