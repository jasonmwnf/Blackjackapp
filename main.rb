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

  def winner!(msg)
    session[:pot] = session[:pot] + session[:bet_amount]
    @success = "#{msg} <strong>#{session[:player_name]} wins!</strong>"
    @display_buttons = false
    @round_over = true
  end

  def loser!(msg)
    session[:pot] = session[:pot] - session[:bet_amount]
    @error = "#{msg} <strong>#{session[:player_name]} loses.</strong>"
    @display_buttons = false
    @round_over = true
  end

  def tie!(msg)
    @success = "<strong>It's a tie!</strong> #{msg}"
    @display_buttons = false
    @round_over = true
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
  session[:pot] = 500
  if params[:player_name].empty?
    @error = "Name is requried!"
    halt erb(:form)
  end

  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do
  erb :bet 
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "You have to place a bet!"
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:pot]
    @error = "You don't have that much to bet! Please enter another amount!"
    halt erb(:bet)
  else
    session[:bet_amount] = params[:bet_amount].to_i
    redirect '/game'
  end
end

get '/game' do
  session[:players_turn] = true
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

    if calc_total(session[:player_cards]) == 21
      winner!("#{session[:player_name]} hit Blackjack!")
    end
    # dealer cards
    # player cards
  erb :game
end

post '/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calc_total(session[:player_cards])
  if player_total == 21
    winner!("#{session[:player_name]} hit Blackjack!")
  elsif player_total > 21
    loser!("#{session[:player_name]} busted.")
  end
  erb :game
end

post '/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @display_buttons = false
  redirect '/dealer_turn'
end

get '/dealer_turn' do
  session[:players_turn] = false
  @players_turn = false

  dealer_total = calc_total(session[:dealer_cards])

  if dealer_total == 21
    loser!("Dealer hit Blackjack.")
  elsif dealer_total > 21
    winner!("Dealer busted.")
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
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and dealer stayed at #{player_total}")
  end

  erb :game
end

get '/game_over' do
  erb :game_over  
end


