pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--gram jam
sale_period_length=1.0
global_demand_weight=1.0
global_demand_rate_mod=1.0
global_base_price_weight=1.0
global_generation_weight=1.0
global_quality_weight=1.0
global_marketing_efficiency=1.0
global_demand_loss=0.01
global_demand_loss_modifier=1.0
global_harvest_speed=1.0
global_cook_speed=1.0
global_sale_volume=1
cash_symbols={"\x98","\x93","\x88","\x85"}
cash_money={50,0,0,0}
jam_timer=0
game_over=false
accountant_unlocked=false
banker_unlocked=false
blockchain_unlocked=false

function add_money(value, scale)
  cash_money[scale]=increment(cash_money[scale],value)
  if cash_money[scale]==32767 then
   if(scale==1 and accountant_unlocked) then
    cash_money[1]=0
    cash_money[2]=increment(cash_money[2],1)
   end
   if(scale==2 and banker_unlocked) then
    cash_money[2]=0
    cash_money[3]=increment(cash_money[3],1)
   end
   if(scale==3 and blockchain_unlocked) then
    cash_money[3]=0
    cash_money[4]=increment(cash_money[4],1)
   end
  end
end

function lose_money(value, scale)
 cash_money[scale]=decrement(cash_money[scale],value)
end

function can_spend(value, scale)
 if (cash_money[scale]-value < 0 or cash_money[scale]-value > cash_money[scale]) return false
 return true
end

function increment(value, num)
 if (num==nil) num=1
 if (value+num<0.01) return 32767
 return value+num
end

function decrement(value, num)
 if (num==nil) num=1
 if (value-num<0) return 0
 return value-num
end


function _init()
 for r in all(recipes) do
  r.discovered=false
 end
 screen = new_start_screen()
end

function _draw()
 screen:draw()
end

function _update()
 if(not game_over) jam_timer=increment(jam_timer,1/30)
 screen:update()
end

-->8
-- screens --
function new_start_screen()
 local s={}
 s.init=function(s)
  game_over=false
  s.opts = {"start game", "credits"}
  s.selected=1
  s.is_selected=false
 end

 s.update=function(s)
  if btnp(5) then s.is_selected=true else s.is_selected=false end
  if (btnp(2)) s.selected=max(s.selected-1,1)
  if (btnp(3)) s.selected=min(s.selected+1,#s.opts)

  if s.is_selected then
   if s.selected==1 then
    screen=new_game_screen()
   end
   if s.selected==2 then
    screen=new_credits_screen()
   end
  end
 end

 s.draw=function(s)
  cls()
  for i=1,#s.opts,1 do
   print(s.opts[i], 50, 60+(10*i))
  end
  spr(32,40,58+(10*s.selected))
  print("gram jam", 40, 20)
  print("the global jam game", 50, 28)
 end

 s:init()
 return s
end


function new_credits_screen()
 local s={}
 s.init=function(s)
  s.opts={"elyjah 'mr ely' wirth", "robert 'rantingbob' gardner", "mari 'make a jam game?' kyle"}
  s.back=false
 end

 s.update=function(s)
  if btnp(4) then s.back=true else s.back=false end

  if s.back then
   screen=new_start_screen()
  end
 end

 s.draw=function(s)
  cls()
  for i=1,#s.opts,1 do
   print(s.opts[i], (5*i), 60+(10*i))
  end
  print("global jam game", 60, 20)
 end

 s:init()
 return s
end

function new_gameover_screen()
 local s={}
 s.init=function(s)
  s.lines={"you have repaired the universe","you have returned all to","the primardial jam"}
  s.back=false
  game_over=true
 end

 s.update=function(s)
  if btnp(4) or btnp(5) then s.back=true else s.back=false end

  if s.back then
   screen=new_start_screen()
  end
 end

 s.draw=function(s)
  cls()
  for i=1,#s.lines,1 do
   print(s.lines[i],(i*10),(i*8))
  end
  sspr(8,32,8,8,48,48,32,32)
  local score="score: "..(32767-jam_timer)
  print(score,64-(4*(#score/2)),82)
 end

 s:init()
 return s
end


function new_game_screen()
 local s={}

 s.init=function(s)
  s.draw_systems={}
  s.update_systems={}
  s.scenes={}
  add(s.scenes, new_farm_scene())
  add(s.scenes, new_kitchen_scene())
  add(s.scenes, new_store_scene())
  add(s.scenes, new_upgrade_scene())
  s.active_scenes={}
  for scene in all(s.scenes) do
   if (scene.unlocked) add(s.active_scenes,scene)
  end
  s.current_scene=1
 end

 s.update=function(s)
  for scene in all(s.scenes) do
   scene:update()
  end

  s.active_scenes[s.current_scene].active=false
  if (btnp(0)) then
   s.current_scene=max(s.current_scene-1,1)
   manberry.update_icon()
  end
  if (btnp(1)) then
   s.current_scene=min(s.current_scene+1,#s.active_scenes)
   manberry.update_icon()
  end
  s.active_scenes[s.current_scene].active=true
 end

 s.draw=function(s)
  cls()
  s.active_scenes[s.current_scene]:draw()

  --draw the transition buttons--
  sspr(s.active_scenes[1].icon.x,s.active_scenes[1].icon.y,32,16,0,104)
  if (s.active_scenes[2]) sspr(s.active_scenes[2].icon.x, s.active_scenes[2].icon.y,32,16,32,104)
  if (s.active_scenes[3]) sspr(s.active_scenes[3].icon.x, s.active_scenes[3].icon.y,32,16,64,104)
  if (s.active_scenes[4]) sspr(s.active_scenes[4].icon.x, s.active_scenes[4].icon.y,32,16,96,104)
  --highlight current button
  local xpos=(s.current_scene-1)*32
  rect(xpos-1,104,xpos+32,119,7)

  local dollar_x=0
  local price=cash_symbols[1]..flr(cash_money[1])
  print(price, dollar_x, 122)
  dollar_x+=(#price*4)+8
  for i=2,#cash_money,1 do
   if cash_money[i] > 0 then
    price=cash_symbols[i]..flr(cash_money[i])
    print(price, dollar_x, 122)
    dollar_x+=(#price*4)+8
   end
  end
 end

 s:init()
 return s
end

-->8
-- upgrade -- store -- kitchen -- farm--
function new_scene()
 local s={}
 s.active=false
 s.unlocked=false
 s.background={
  x=0,
  y=0
 }
 s.icon={
  x=0,
  y=0
 }
 return s
end

function new_upgrade_scene()
 local s=new_scene()
 s.background.x=48
 s.unlocked=false
 s.icon.x=88
 s.icon.y=32

 s.available_upgrades={}
 s.purchased_upgrades={}
 s.selected_upgrade=1

 s.update=function(scene)
  check_for_unlocks(scene)

  for upgrade in all(scene.purchased_upgrades) do
   if (upgrade.update) upgrade.update(scene)
  end
  if scene.active and #scene.available_upgrades>0 then
   if btnp(2) then
    scene.selected_upgrade=max(scene.selected_upgrade-1, 1)
   end
   if btnp(3) then
    scene.selected_upgrade=min(scene.selected_upgrade+1, #scene.available_upgrades)
   end

   local selected=scene.available_upgrades[scene.selected_upgrade]
   if(not selected.quantity) selected.quantity=0
   if btnp(5) and can_spend(selected.price, selected.scale) and selected.quantity < selected.max_quantity then
    if not (selected==banker or selected==accountant or selected==blockchain) then
     if (selected.quantity==0) add(s.purchased_upgrades, selected)
    end
    selected.quantity=increment(selected.quantity)
    if(selected.on_purchase) selected.on_purchase(scene)
    lose_money(selected.price, selected.scale)
    if selected.quantity == selected.max_quantity then
     del(s.available_upgrades, selected)
     s.selected_upgrade=1
    end
   end
  end
 end

 s.draw=function(scene)
  map(scene.background.x,scene.background.y,0,0,16,16)

  local page=flr(abs(scene.selected_upgrade-1)/4)
  local loop_start=(page*4)+1
  local loop_end=min(loop_start+3, #scene.available_upgrades)
  local row=0

  for i=loop_start,loop_end,1 do
   local upgrade = scene.available_upgrades[i]
   local icon=upgrade.icon
   local x_pix=(icon*8)%128
   local y_pix=flr(abs(icon/16))*8
   local x_target=65
   local y_target=(row*24)
   local price=cash_symbols[upgrade.scale]..upgrade.price

   sspr(x_pix,y_pix,8,8,x_target,y_target,16,16)
   print(price,x_target,y_target+17)
   if (i==scene.selected_upgrade) rect(x_target-1,y_target-1,x_target+16,y_target+16,7)
   row+=1
   if (row>4) row=0
  end

  for i=1,#scene.purchased_upgrades,1 do
   local upgrade = scene.purchased_upgrades[i]
    local icon=upgrade.icon
    local x_pix=(icon*8)%128
    local y_pix=flr(abs(icon/16))*8
    local x_target=1
    local y_target=8+((i-1)*18)

    sspr(x_pix,y_pix,8,8,x_target,y_target,16,16)
    print(upgrade.quantity,x_target+17,y_target)
  end

  if #scene.available_upgrades>0 then
   print(scene.available_upgrades[scene.selected_upgrade].name, 0, 1)
   print(scene.available_upgrades[scene.selected_upgrade].description, 0, 96)
  end

 end

 return s
end


function new_store_scene()
 local s=new_scene()
 s.background.x=32
 s.unlocked=false
 s.icon.x=56
 s.icon.y=32
 granimation=128
 granimation_time=0

 s.stock={}
 s.selected_stock=1

 s.update=function(scene)
  --ely futsin here--
  if time() - granimation_time > 1 then
   granimation_time=time()
   granimation+=4
   if granimation>136 then granimation = 128 end
  end
  ----

  --update sale period counters for jams
  for jam in all(scene.stock) do
   if jam.sale_period_counter==nil then jam.sale_period_counter=0 end
   jam.sale_period_counter=increment(jam.sale_period_counter,1/30)
   if jam.sale_period_counter > sale_period_length then
    local temp_demand = get_demand(jam)+(jam.demand_rate*global_demand_rate_mod)
    if (temp_demand < 0) temp_demand=32767
    jam.demand=temp_demand
    jam.sale_period_counter=0.0
   end
  end
  --stock list selected--
  if scene.active and #scene.stock>0 then
   if btnp(2) then
    scene.selected_stock=max(scene.selected_stock-1, 1)
   end
   if btnp(3) then
    scene.selected_stock=min(scene.selected_stock+1, #scene.stock)
   end
   if btnp(5) and scene.stock[scene.selected_stock].quantity > 0 then
    sold(scene.stock[scene.selected_stock])
   end

  end
 end

 s.draw=function(scene)
  map(scene.background.x,scene.background.y,0,0,16,16)
  spr(granimation,20,24,4,4)

  --draw stock list--
  local column=0
  local row=0
  local page=flr(abs(scene.selected_stock-1)/12)
  local loop_start=(page*12)+1
  local loop_end=min(loop_start+11, #scene.stock)

  for i=loop_start,loop_end,1 do
   local ing=scene.stock[i]
   local icon=ing.icon()
   local x_pix=(icon*8)%128
   local y_pix=flr(abs(icon/16))*8
   local x_target=(8+(column*3))*8
   local y_target=(row*3)*8
   sspr(x_pix,y_pix,8,8,x_target,y_target,16,16)
   print(ing.quantity,x_target,y_target+16)
   column+=1
   column%=3
   if (column==0) row+=1
   if (i==scene.selected_stock) rect(x_target-1,y_target-1,x_target+16,y_target+16,7)
  end

  if #scene.stock > 0 then
   local name=scene.stock[scene.selected_stock].shortname
   local price=cash_symbols[scene.stock[scene.selected_stock].scale]..get_price(scene.stock[scene.selected_stock])
   local demand=""..get_demand(scene.stock[scene.selected_stock]).."*"
   print(name, 0, 1)
   print("sale price:",8,64)
   print(price, 56-(#price*4+4), 72)
   print("demand:",8,80)
   print(demand,56-(#demand*4),88)
  end
 end

 return s
end

function new_farm_scene()
 local s=new_scene()
 s.unlocked=true
 s.icon={
  x=96,
  y=0
 }
 s.bushes={}
 s.planted_bushes={}
 add(s.bushes, strawberry_bush)

 s.selected=1

 s.update=function(scene)
  for bush in all(scene.planted_bushes) do
   bush.harvest_counter=increment(bush.harvest_counter,1/30)
  end

  if scene.active then
   if btnp(2) then
    scene.selected=max(scene.selected-1, 1)
   end
   if btnp(3) then
    scene.selected=min(scene.selected+1, #scene.bushes)
   end
   if btnp(5) then
    local desired_bush=scene.bushes[scene.selected]
    if can_spend(desired_bush.price, desired_bush.scale) then
     local new_bush={
      x=rnd(48),
      y=rnd(49)+40,
      template=desired_bush,
      harvest_counter=0.0
     }
     add(scene.planted_bushes, new_bush)
     lose_money(desired_bush.price, desired_bush.scale)
     if(not desired_bush.quantity) desired_bush.quantity=0
     desired_bush.quantity=increment(desired_bush.quantity)
    end
   end
   if btnp(4) then
    harvest(scene)
   end
  end
 end

 s.draw=function(scene)
  map(scene.background.x,scene.background.y,0,0,16,16)
  local page=flr(abs(scene.selected-1)/4)
  local loop_start=(page*4)+1
  local loop_end=min(loop_start+3, #scene.bushes)
  local row=0

  for i=loop_start,loop_end,1 do
   local bush = scene.bushes[i]
   local icon=bush.icon
   local x_pix=(icon*8)%128
   local y_pix=flr(abs(icon/16))*8
   local x_target=65
   local y_target=(row*24)
   local price=cash_symbols[bush.scale]..bush.price

   sspr(x_pix,y_pix,8,8,x_target,y_target,16,16)
   print(price,x_target+18,y_target+2)
   if(not bush.quantity) bush.quantity=0
   print(bush.quantity,x_target+18,y_target+12)
   if (i==scene.selected) rect(x_target-1,y_target-1,x_target+16,y_target+16,7)
   row+=1
   if (row>4) row=0
   print(scene.bushes[scene.selected].name, 0, 96)

  end


  local l=#scene.planted_bushes
  local l_min=max(l-100,1)
  local l_max=min(l,l_min+100)
  for i=l_min,l_max,1 do
   local bush=scene.planted_bushes[i]
   local icon=bush.template.icon
   if (bush.template.harvest_time >= bush.harvest_counter) icon=emptybush_icon
   spr(icon,bush.x,bush.y)
  end
 end

 return s
end

function new_kitchen_scene()
 local s=new_scene()
 s.background.x=16
 s.unlocked=false
 s.icon={
  x=24,
  y=32
 }

 s.process_mix=false
 s.mix_complete=false
 s.mixer_contents={}
 s.available_ingredients={}
 s.selected_ingredient=1

 s.update=function(scene)
  if scene.mix_complete then
   gain_jam(scene.current_output)
   scene.current_output=nil
   scene.mixer_contents={}
   scene.mix_complete=false
   scene.process_mix=false
  end

  if scene.process_mix and not scene.mix_complete then
   scene:advance_mix()
  end

  --ingredient list selected--
  if scene.active and #scene.available_ingredients>0 then
   if btnp(2) then
    scene.selected_ingredient=max(scene.selected_ingredient-1, 1)
   end
   if btnp(3) then
    scene.selected_ingredient=min(scene.selected_ingredient+1, #scene.available_ingredients)
   end
   if btnp(5) and #scene.mixer_contents<3 and scene.available_ingredients[scene.selected_ingredient].quantity > 0 then
    add(scene.mixer_contents, scene.available_ingredients[scene.selected_ingredient])
    scene.available_ingredients[scene.selected_ingredient].quantity = decrement(scene.available_ingredients[scene.selected_ingredient].quantity)
   end
   if #scene.mixer_contents!=0 then
    scene.current_recipe = lookup_recipe(scene.mixer_contents)
    if scene.current_recipe and scene.current_recipe.output then scene.current_output=scene.current_recipe.output else scene.current_output=badjam end
    if btnp(4) then
     scene.process_mix=true
     if scene.current_recipe then
      if not scene.current_recipe.discovered then
       scene.current_recipe.discovered=true
       add(known_good_recipes, scene.current_recipe)
      end
     end
    end
   end
  end
 end

 s.advance_mix=function(scene)
  scene.mix_complete=true
 end

 s.draw=function(scene)
  map(scene.background.x,scene.background.y,0,0,16,16)

  --draw ingredient list--
  local column=0
  local row=0
  local page=flr(abs(scene.selected_ingredient-1)/12)
  local loop_start=(page*12)+1
  local loop_end=min(loop_start+11, #scene.available_ingredients)

  for i=loop_start,loop_end,1 do
   local ing=scene.available_ingredients[i]
   local icon=ing.icon()
   local x_pix=(icon*8)%128
   local y_pix=flr(abs(icon/16))*8
   local x_target=(8+(column*3))*8
   local y_target=(row*3)*8
   sspr(x_pix,y_pix,8,8,x_target,y_target,16,16)
   print(ing.quantity,x_target,y_target+16)
   column+=1
   column%=3
   if (column==0) row+=1
   if (i==scene.selected_ingredient) rect(x_target-1,y_target-1,x_target+16,y_target+16,7)
  end

  --draw mixer--
  if (scene.mixer_contents[1]) spr(scene.mixer_contents[1].icon(),8,8)
  if (scene.mixer_contents[2]) spr(scene.mixer_contents[2].icon(),24,8)
  if (scene.mixer_contents[3]) spr(scene.mixer_contents[3].icon(),40,8)
  if #scene.available_ingredients > 0 then
   local name = scene.available_ingredients[scene.selected_ingredient].shortname
   print(name,0,0)
  end
  local icon=4
  if (scene.current_output) icon=scene.current_output.icon()
  sspr((icon*8)%128,flr(abs(icon/16))*8,8,8,16,48,24,24)

 end

 return s
end

-->8
--ingredients--
function get_price(jam)
 local base_price=get_base_price(jam)
 local multiplier=get_generatoin_modifier(jam) * get_demand(jam) * global_marketing_efficiency
 local loop_end=flr(multiplier)
 local price=0
 for i=1,loop_end,1 do
  price=increment(price, base_price)
  multiplier=decrement(multiplier, 1)
  if(price==32767) return price
 end

 return increment(price, base_price*multiplier)
end

function get_generatoin_modifier(jam)
 return jam.gen*global_generation_weight
end

function get_base_price(jam)
 return jam.base_price * global_base_price_weight * global_quality_weight
end

function get_demand(jam)
 if(jam.demand==nil) jam.demand=1
 return jam.demand*global_demand_weight
end

function sold(jam)
 for i=1,min(jam.quantity, global_sale_volume),1 do
  add_money(get_price(jam), jam.scale)
  jam.demand = max(decrement(jam.demand,global_demand_loss*global_demand_loss_modifier), 0.01)
  jam.quantity=decrement(jam.quantity)
 end

 jam.sale_period_counter=0
end

strawberry={
 shortname="strawberry",
 unlocked=false,
 icon=function() return 16 end,
}

blueberry={
 shortname="blueberry",
 unlocked=false,
 icon=function() return 17 end,
}

bananaberry={
 shortname="bananaberry",
 unlocked=false,
 icon=function() return 63 end,
}

manberry={
 shortname="manberry",
 unlocked=false,
 icon_options={18,19,20,21,22},
 current_icon=1,
 icon=function() return manberry.icon_options[manberry.current_icon] end,
 update_icon=function()
  manberry.current_icon=flr(rnd(#manberry.icon_options)+1)
 end,
}

globerry={
 shortname="globerry",
 unlocked=false,
 icon=function() return 23 end,
}

bigberry={
 shortname="bigberry",
 unlocked=false,
 icon=function() return 24 end,
}

bangberry={
 shortname="bangberry",
 unlocked=false,
 icon=function() return 25 end,
}

darkberry={
 shortname="darkberry",
 unlocked=false,
 icon=function() return 26 end,
}

galactiberry={
 shortname="galactiberry",
 unlocked=false,
 icon=function() return 27 end,
}

strawberryjam={
 shortname="strawberry jam",
 unlocked=false,
 icon=function() return 1 end,
 base_price=2,
 demand_rate=0.01,
 gen=1,
 scale=1
}

strawberrytrijam={
 shortname="s.tribery jam",
 unlocked=false,
 icon=function() return 1 end,
 base_price=6,
 demand_rate=0.01,
 gen=1,
 scale=1
}

strawberrynanajam={
 shortname="s.nanabery jam",
 unlocked=false,
 icon=function() return 1 end,
 base_price=18,
 demand_rate=0.01,
 gen=1,
 scale=1
}

bananaberryjam={
 shortname="bananajama",
 unlocked=false,
 icon=function() return 9 end,
 base_price=10,
 demand_rate=0.01,
 gen=1,
 scale=2
}

bananaberrytrijam={
 shortname="bananatrijama",
 unlocked=false,
 icon=function() return 9 end,
 base_price=40,
 demand_rate=0.01,
 gen=1,
 scale=2
}

bananaberrynanajam={
 shortname="bananananajama",
 unlocked=false,
 icon=function() return 9 end,
 base_price=500,
 demand_rate=0.01,
 gen=2,
 scale=2
}

blueberryjam={
 shortname="blueberry jam",
 unlocked=false,
 icon=function() return 2 end,
 base_price=10,
 demand_rate=0.01,
 gen=1,
 scale=1
}

blueberrytrijam={
 shortname="b.tribery jam",
 unlocked=false,
 icon=function() return 2 end,
 base_price=30,
 demand_rate=0.01,
 gen=1,
 scale=1
}

blueberrynanajam={
 shortname="b.nanabery jam",
 unlocked=false,
 icon=function() return 2 end,
 base_price=90,
 demand_rate=0.01,
 gen=2,
 scale=1
}

manberryjam={
 shortname="manberry jam",
 unlocked=false,
 icon=function() return 5 end,
 base_price=250,
 demand_rate=0.02,
 gen=1,
 scale=1
}

manberrytrijam={
 shortname="m.triberry jam",
 unlocked=false,
 icon=function() return 11 end,
 base_price=500,
 demand_rate=0.04,
 gen=1,
 scale=1
}

manberrynanajam={
 shortname="mananabery jam",
 unlocked=false,
 icon=function() return 64 end,
 base_price=1000,
 demand_rate=0.06,
 gen=2,
 scale=1
}

bluemanberryjam={
 shortname="blumanbery jam",
 unlocked=false,
 icon=function() return 8 end,
 base_price=1,
 demand_rate=0.01,
 gen=2,
 scale=2
}

strawmanberryjam={
 shortname="s.manberry jam",
 unlocked=false,
 icon=function() return 7 end,
 base_price=250,
 demand_rate=0.01,
 gen=2,
 scale=1
}

bluestrawberyjam={
 shortname="b.s.berry jam",
 unlocked=false,
 icon=function() return 6 end,
 base_price=20,
 demand_rate=0.03,
 gen=2,
 scale=1
}

bluemanstrawberyjam={
 shortname="b.m.s.bery jam",
 unlocked=false,
 icon=function() return 10 end,
 base_price=1,
 demand_rate=0.01,
 gen=3,
 scale=2
}

globerryjam={
 shortname="globerry jam",
 unlocked=false,
 icon=function() return 33 end,
 base_price=250,
 demand_rate=0.02,
 gen=1,
 scale=2
}

globtriberryjam={
 shortname="g.triberry jam",
 unlocked=false,
 icon=function() return 33 end,
 base_price=500,
 demand_rate=0.02,
 gen=1,
 scale=2
}

globnanaberryjam={
 shortname="g.nanabery jam",
 unlocked=false,
 icon=function() return 33 end,
 base_price=1000,
 demand_rate=0.02,
 gen=2,
 scale=2
}

globlueberryjam={
 shortname="g.b.berry jam",
 unlocked=false,
 icon=function() return 34 end,
 base_price=250,
 demand_rate=0.04,
 gen=2,
 scale=2
}

globstrawberryjam={
 shortname="g.s.berry jam",
 unlocked=false,
 icon=function() return 36 end,
 base_price=250,
 demand_rate=0.04,
 gen=2,
 scale=2
}

globmanberryjam={
 shortname="g.manberry jam",
 unlocked=false,
 icon=function() return 37 end,
 base_price=200,
 demand_rate=0.01,
 gen=3,
 scale=2
}

globluestrawberryjam={
 shortname="g.b.s.bery jam",
 unlocked=false,
 icon=function() return 38 end,
 base_price=350,
 demand_rate=0.06,
 gen=4,
 scale=2
}

globluemanberryjam={
 shortname="g.b.m.bery jam",
 unlocked=false,
 icon=function() return 39 end,
 base_price=250,
 demand_rate=0.03,
 gen=4,
 scale=2
}

globstrawmanberryjam={
 shortname="g.s.m.bery jam",
 unlocked=false,
 icon=function() return 56 end,
 base_price=250,
 demand_rate=0.03,
 gen=4,
 scale=2
}

galactijam={
 shortname="globerry jam",
 unlocked=false,
 icon=function() return 66 end,
 base_price=10,
 demand_rate=0.01,
 gen=1,
 scale=3
}

galactilactilactijam={
 shortname="galactrijam",
 unlocked=false,
 icon=function() return 66 end,
 base_price=30,
 demand_rate=0.01,
 gen=1,
 scale=3
}

galactinanajam={
 shortname="galactinanajam",
 unlocked=false,
 icon=function() return 66 end,
 base_price=90,
 demand_rate=0.01,
 gen=1,
 scale=3
}

glactiblueberryjam={
 shortname="galactib. jam",
 unlocked=false,
 icon=function() return 112 end,
 base_price=10,
 demand_rate=0.03,
 gen=2,
 scale=3
}

glactistrawberryjam={
 shortname="galactis. jam",
 unlocked=false,
 icon=function() return 113 end,
 base_price=10,
 demand_rate=0.05,
 gen=2,
 scale=3
}

galactimanberryjam={
 shortname="galactim. jam",
 unlocked=false,
 icon=function() return 114 end,
 base_price=10,
 demand_rate=0.02,
 gen=3,
 scale=3
}

galactigloberryjam={
 shortname="galactig. jam",
 unlocked=false,
 icon=function() return 57 end,
 base_price=10,
 demand_rate=0.075,
 gen=4,
 scale=3
}

galactibluestrawberryjam={
 shortname="galactib.s.jam",
 unlocked=false,
 icon=function() return 58 end,
 base_price=10,
 demand_rate=0.04,
 gen=3,
 scale=3
}

galactibluemanberryjam={
 shortname="galactib.m.jam",
 unlocked=false,
 icon=function() return 59 end,
 base_price=10,
 demand_rate=0.01,
 gen=4,
 scale=3
}

galactibluegloberryjam={
 shortname="galactib.g.jam",
 unlocked=false,
 icon=function() return 79 end,
 base_price=10,
 demand_rate=0.01,
 gen=5,
 scale=3
}

galactistrawmanberryjam={
 shortname="galactis.m.jam",
 unlocked=false,
 icon=function() return 111 end,
 base_price=10,
 demand_rate=0.03,
 gen=4,
 scale=3
}

galctistrawgloberryjam={
 shortname="galactis.g.jam",
 unlocked=false,
 icon=function() return 95 end,
 base_price=10,
 demand_rate=0.6,
 gen=5,
 scale=3
}

galactiglobemanberryjam={
 shortname="galactig.m.jam",
 unlocked=false,
 icon=function() return 127 end,
 base_price=10,
 demand_rate=0.045,
 gen=6,
 scale=3
}

darkjam={
 shortname="dark jam",
 unlocked=false,
 icon=function() return 80 end,
 base_price=25,
 demand_rate=0.01,
 gen=1,
 scale=4
}

darktrijam={
 shortname="darktri jam",
 unlocked=false,
 icon=function() return 80 end,
 base_price=80,
 demand_rate=0.02,
 gen=1,
 scale=4
}

darknanajam={
 shortname="darknana jam",
 unlocked=false,
 icon=function() return 80 end,
 base_price=250,
 demand_rate=0.03,
 gen=2,
 scale=4
}

bigberryjam={
 shortname="bigberry jam",
 unlocked=false,
 icon=function() return 82 end,
 base_price=5,
 demand_rate=0.1,
 gen=1,
 scale=2
}

bigtriberryjam={
 shortname="bigtribery jam",
 unlocked=false,
 icon=function() return 82 end,
 base_price=50,
 demand_rate=0.05,
 gen=1,
 scale=2
}

bignanaberryjam={
 shortname="biganabery jam",
 unlocked=false,
 icon=function() return 82 end,
 base_price=250,
 demand_rate=0.01,
 gen=2,
 scale=2
}

bangberryjam={
 shortname="bangberry jam",
 unlocked=false,
 icon=function() return 96 end,
 base_price=1,
 demand_rate=0.01,
 gen=3,
 scale=4
}

bangtriberryjam={
 shortname="bangtriberyjam",
 unlocked=false,
 icon=function() return 96 end,
 base_price=15,
 demand_rate=0.01,
 gen=1,
 scale=4
}

bangnanaberryjam={
 shortname="bangnanabeyjam",
 unlocked=false,
 icon=function() return 96 end,
 base_price=30,
 demand_rate=0.07,
 gen=2,
 scale=4
}

chaosjam={
 shortname="chaos jam",
 unlocked=false,
 icon=function() return 172 end,
 base_price=1,
 demand_rate=0.01,
 gen=2,
 scale=4
}

alphachaosjam={
 shortname="alphachaos jam",
 unlocked=false,
 icon=function() return 172 end,
 base_price=10,
 demand_rate=0.04,
 gen=3,
 scale=4
}

omegachaosjam={
 shortname="omegachaos jam",
 unlocked=false,
 icon=function() return 172 end,
 base_price=50,
 demand_rate=0.1,
 gen=4,
 scale=4
}

badjam={
 shortname="bad jam",
 unlocked=false,
 icon=function() return 3 end,
 base_price=1,
 demand_rate=0.01,
 gen=1,
 scale=1
}

badtrijam={
 shortname="badtri jam",
 unlocked=false,
 icon=function() return 3 end,
 base_price=3,
 demand_rate=0.01,
 gen=1,
 scale=1
}

badnanajam={
 shortname="badnana jam",
 unlocked=false,
 icon=function() return 3 end,
 base_price=10,
 demand_rate=0.05,
 gen=2,
 scale=1
}

bigbangjam={
 shortname="bigbang jam",
 unlocked=false,
 icon=function() return 81 end,
 base_price=100,
 demand_rate=0.01,
 gen=2,
 scale=4
}

primordialjam={
 shortname="primordial jam",
 unlocked=false,
 icon=function() return 65 end,
 base_price=32767,
 demand_rate=10,
 gen=6,
 scale=4
}

-->8
--manufacturing
function harvest(scene, num)
 if not num then num=32767 end
 local counter=0
 for bush in all(scene.planted_bushes) do
  if bush.harvest_counter > bush.template.harvest_time  and counter < num then
   harvest_bush(bush)
   counter+=1
  end
 end
end

function harvest_bush(bush)
 bush.harvest_counter=0.0
 if not screen.active_scenes[2] then
  screen.active_scenes[2]=screen.scenes[2]
  screen.active_scenes[2].unlocked=true
 end
 if(not bush.template.produce.quantity) bush.template.produce.quantity=0
 bush.template.produce.quantity=increment(bush.template.produce.quantity)
 if not bush.template.produce.unlocked then
  add(screen.active_scenes[2].available_ingredients, bush.template.produce)
  bush.template.produce.unlocked=true
 end
end

emptybush_icon=51

strawberry_bush={
 name="strawberry bush",
 icon=48,
 price=10,
 scale=1,
 produce=strawberry,
 harvest_time=10.0,
 unlocked=true,
}

blueberry_bush={
 name="blueberry bush",
 icon=52,
 price=100,
 scale=1,
 produce=blueberry,
 harvest_time=3,
 unlocked=false,
}

bananaberry_bush={
 name="bananaberry bush",
 icon=62,
 price=2500,
 scale=2,
 produce=bananaberry,
 harvest_time=25.0,
 unlocked=false,
}

manberry_bush={
 name="manberry bush",
 icon=49,
 price=10,
 scale=2,
 produce=manberry,
 harvest_time=100.0,
 unlocked=false,
}

globerry_bush={
 name="globerry bush",
 icon=229,
 price=1,
 scale=3,
 produce=globerry,
 harvest_time=100.0,
 unlocked=false,
}

bigberry_bush={
 name="bigberry bush",
 icon=230,
 price=100,
 scale=2,
 produce=bigberry,
 harvest_time=50.0,
 unlocked=false,
}

bangberry_bush={
 name="bangberry bush",
 icon=231,
 price=1,
 scale=3,
 produce=bangberry,
 harvest_time=1.0,
 unlocked=false,
}

darkberry_bush={
 name="darkberry bush",
 icon=232,
 price=32767,
 scale=4,
 produce=darkberry,
 harvest_time=10.0,
 unlocked=false,
}

galactiberry_bush={
 name="galactiberry bush",
 icon=233,
 price=10000,
 scale=3,
 produce=galactiberry,
 harvest_time=10.0,
 unlocked=false,
}

-->8
--recipes--
known_good_recipes={}

function has_ingredients(recipe)
 input1=0
 input2=0
 input3=0
 if #recipe.inputs==1 then
  if (recipe.inputs[1].quantity==0) return false
  input1 = recipe.inputs[1].quantity-1
 end

 if #recipe.inputs==2 then
  if (recipe.inputs[1].quantity==0) return false
  if (recipe.inputs[2].quantity==0) return false
  input1 = recipe.inputs[1].quantity-1
  input2 = recipe.inputs[2].quantity-1
  if (recipe.inputs[1]==recipe.inputs[2]) input2=decrement(input2)
 end

 if #recipe.inputs==3 then
  if (recipe.inputs[1].quantity==0) return false
  if (recipe.inputs[2].quantity==0) return false
  if (recipe.inputs[3].quantity==0) return false
  input1 = recipe.inputs[1].quantity-1
  input2 = recipe.inputs[2].quantity-1
  input3 = recipe.inputs[3].quantity-1
  if (recipe.inputs[1]==recipe.inputs[2]) input2=decrement(input2)
  if (recipe.inputs[1]==recipe.inputs[3]) input3=decrement(input3)
  if (recipe.inputs[2]==recipe.inputs[3]) input3=decrement(input3)
 end

 if input1<0 or input2<0 or input3<0 then return false else return true end
end

function spend_ingredients(recipe)
 for input in all(recipe.inputs) do
  input.quantity=decrement(input.quantity)
 end
end

function gain_jam(jam)
 if(not jam.quantity) jam.quantity=0
 store=screen.active_scenes[3]
 jam.quantity=increment(jam.quantity)
 if not jam.unlocked then
  jam.unlocked=true
  add(screen.active_scenes[2].available_ingredients, jam)
  if not screen.active_scenes[3] then
   screen.active_scenes[3]=screen.scenes[3]
   screen.active_scenes[3].unlocked=true
  end
  add(screen.active_scenes[3].stock, jam)
 end
end

function lookup_recipe(mixer_contents)
 local output=false
 local temp_recipes={}
 local final_matches={}
 local temp_matches={}
 --make a sublist of recipes where inputs length is the same as mixer contents length
 for check in all(recipes) do
  if (#check.inputs==#mixer_contents) add(temp_recipes,check)
 end

 --filter out recipes that don't contain element 1
 if #mixer_contents==1 then
  for recipecheck in all(temp_recipes) do
   local used1=false
   if (recipecheck.inputs[1] == mixer_contents[1]) add(final_matches,recipecheck)
  end
 end

  --filter out recupes that don't contain element 2
 if #mixer_contents==2 then
  for recipecheck in all(temp_recipes) do

   local used1=false
   local used2=false

   if recipecheck.inputs[1] == mixer_contents[1] then
    used1=true
    goto twoinputsecondcheck
   end
   if (recipecheck.inputs[1] == mixer_contents[2]) used2=true

   ::twoinputsecondcheck::
   if recipecheck.inputs[2] == mixer_contents[1] then
    used1=true
    goto twoinputend
   end
   if (recipecheck.inputs[2] == mixer_contents[2]) used2=true

   ::twoinputend::
   if (used1 and used2) add(temp_matches,recipecheck)
  end
  final_matches=temp_matches
 end

  --filter out recupes that don't contain element 3
 if #mixer_contents==3 then
  for recipecheck in all(temp_recipes) do
   local used1=false
   local used2=false
   local used3=false

   if recipecheck.inputs[1] == mixer_contents[1] then
    used1=true
    goto threeinputsecondcheck
   end
   if recipecheck.inputs[1] == mixer_contents[2] then
    used2=true
    goto threeinputsecondcheck
   end
    if (recipecheck.inputs[1] == mixer_contents[3]) used3=true

   ::threeinputsecondcheck::
   if recipecheck.inputs[2] == mixer_contents[1] and not used1 then
    used1=true
    goto threeinputthirdcheck
   end

   if recipecheck.inputs[2] == mixer_contents[2] and not used2 then
    used2=true
    goto threeinputthirdcheck
   end

   if (recipecheck.inputs[2] == mixer_contents[3] and not used3) used3=true

   ::threeinputthirdcheck::
   if recipecheck.inputs[3] == mixer_contents[1] and not used1 then
    used1=true
    goto threeinputend
   end
   if recipecheck.inputs[3] == mixer_contents[2] and not used2 then
    used2=true
    goto threeinputend
   end
   if (recipecheck.inputs[3] == mixer_contents[3] and not used3) used3=true

   ::threeinputend::
   if (used1 and used2 and used3) add(temp_matches,recipecheck)
  end
  final_matches=temp_matches
 end

  --return the only remaining recipe
 if #final_matches > 0 then
  output=final_matches[1]
 end

  return output
end

recipes={
 --strawberry jam--
 {
  inputs={
   strawberry
  },
  output=strawberryjam
 },
 --strawtriberry jam--
 {
  inputs={
   strawberry,
   strawberry,
   strawberry
  },
  output=strawberrytrijam
 },
 --strawnanaberry jam--
 {
  inputs={
   strawberrytrijam,
   strawberrytrijam,
   strawberrytrijam,
  },
  output=strawberrynanajam
 },
 {
  inputs={
   strawberry,
   bananaberry
  },
  output=strawberrynanajam
 },

 --blueberry jam--
 {
  inputs={
   blueberry
  },
  output=blueberryjam
 },
--bluetriberry jam--
 {
  inputs={
   blueberry,
   blueberry,
   blueberry
  },
  output=blueberrytrijam
 },
 --bluenanaberry jam--
 {
  inputs={
   blueberrytrijam,
   blueberrytrijam,
   blueberrytrijam,
  },
  output=blueberrynanajam
 },
 {
  inputs={
   blueberry,
   bananaberry
  },
  output=blueberrynanajam
 },
--bananaberry jam--
 {
  inputs={
   bananaberry
  },
  output=bananaberryjam
 },
--bananatriberry jam--
 {
  inputs={
   bananaberry,
   bananaberry,
   bananaberry
  },
  output=bananaberrytrijam
 },
 --bananananaberry jam--
 {
  inputs={
   bananaberrytrijam,
   bananaberrytrijam,
   bananaberrytrijam,
  },
  output=bananaberrynanajam
 },
--manberry jam--
 {
  inputs={
   manberry
  },
  output=manberryjam
 },
 --mantriberry jam--
 {
  inputs={
   manberry,
   manberry,
   manberry
  },
  output=manberrytrijam
 },
 --mananaberry jam
 {
  inputs={
   manberrytrijam,
   manberrytrijam,
   manberrytrijam
  },
  output=manberrynanajam
 },
 {
  inputs={
   manberry,
   bananaberry
  },
  output=manberrynanajam
 },
 --bluemanbery jam
 {
  inputs={
   blueberry,
   manberry,
  },
  output=bluemanberryjam
 },
 --strawmanbery jam
 {
  inputs={
   strawberry,
   manberry,
  },
  output=strawmanberryjam
 },
 --bluestrawbery jam
 {
  inputs={
   strawberry,
   blueberry
  },
  output=bluestrawberyjam
 },

--bluemanstrawbery jam
 {
  inputs={
   strawberry,
   manberry,
   blueberry
  },
  output=bluemanstrawberyjam
 },
--globerry jam--
 {
  inputs={
   globerry,
  },
  output=globerryjam
 },
 --globtriberry jam--
 {
  inputs={
   globerry,
   globerry,
   globerry,
  },
  output=globtriberryjam
 },
 --globnanaberry jam--
 {
  inputs={
   globtriberryjam,
   globtriberryjam,
   globtriberryjam,
  },
  output=globnanaberryjam
 },
 {
  inputs={
   globerry,
   bananaberry
  },
  output=globnanaberryjam
 },

 --globblueberry jam--
 {
  inputs={
   globerry,
   blueberry
  },
  output=globlueberryjam
 },
--globstrawberry jam--
 {
  inputs={
   globerry,
   strawberry
  },
  output=globstrawberryjam
 },
--globmanberry jam--
 {
  inputs={
   globerry,
   manberry
  },
  output=globmanberryjam
 },
 --globluestrawberry jam--
 {
  inputs={
   globerry,
   strawberry,
   blueberry
  },
  output=globluestrawberryjam
 },
--globluemanberry jam--
 {
  inputs={
   globerry,
   manberry,
   blueberry
  },
  output=globluemanberryjam
 },
--glostrawmanberry jam--
 {
  inputs={
   globerry,
   manberry,
   strawberry
  },
  output=globstrawmanberryjam
 },
--galactijam--
 {
  inputs={
   galactiberry,
  },
  output=galactijam
 },
 --galactrijam--
 {
  inputs={
   galactiberry,
   galactiberry,
   galactiberry,
  },
  output=galactilactilactijam
 },
 --galactinanajam--
 {
  inputs={
   galactilactilactijam,
   galactilactilactijam,
   galactilactilactijam,
  },
  output=galactinanajam
 },
 {
  inputs={
   galactiberry,
   bananaberry
  },
  output=galactinanajam
 },
 --galactibluejam--
 {
  inputs={
   galactiberry,
   blueberry
  },
  output=glactiblueberryjam
 },
 --galactistrawjam--
 {
  inputs={
   galactiberry,
   strawberry
  },
  output=glactistrawberryjam
 },
 --galactimanjam--
 {
  inputs={
   galactiberry,
   manberry
  },
  output=galactimanberryjam
 },
 --galactiglobejam--
 {
  inputs={
   galactiberry,
   globerry
  },
  output=galactigloberryjam
 },
 --galactibluestrawberryjam--
 {
  inputs={
   galactiberry,
   blueberry,
   strawberry
  },
  output=galactibluestrawberryjam
 },

 --galactibluestrawberryjam--
 {
  inputs={
   galactiberry,
   blueberry,
   manberry
  },
  output=galactibluemanberryjam
 },
 --galactibluestrawberryjam--
 {
  inputs={
   galactiberry,
   blueberry,
   globerry
  },
  output=galactibluegloberryjam
 },
 --galactistrawmanberryjam--
 {
  inputs={
   galactiberry,
   strawberry,
   manberry
  },
  output=galactistrawmanberryjam
 },

 --galctistrawgloberryjam--
 {
  inputs={
   galactiberry,
   strawberry,
   globerry
  },
  output=galctistrawgloberryjam
 },

 --galactiglobemanberryjam--
 {
  inputs={
   galactiberry,
   manberry,
   globerry
  },
  output=galactiglobemanberryjam
 },
 --dark jam--
 {
  inputs={
   darkberry,
  },
  output=darkjam
 },
 --darktri jam--
 {
  inputs={
   darkberry,
   darkberry,
   darkberry,
  },
  output=darktrijam
 },
 --darknana jam--
 {
  inputs={
   darktrijam,
   darktrijam,
   darktrijam,
  },
  output=darknanajam
 },
 {
  inputs={
   darkberry,
   bananaberry
  },
  output=darknanajam
 },
 --big jam--
 {
  inputs={
   bigberry,
  },
  output=bigberryjam
 },

 --bigtri jam--
 {
  inputs={
   bigberry,
   bigberry,
   bigberry,
  },
  output=bigtriberryjam
 },
 --bignana jam--
 {
  inputs={
   bigtriberryjam,
   bigtriberryjam,
   bigtriberryjam,
  },
  output=bignanaberryjam
 },
 {
  inputs={
   bigberry,
   bananaberry
  },
  output=bignanaberryjam
 },

 --bang jam--
 {
  inputs={
   bangberry,
  },
  output=bangberryjam
 },

 --bigtri jam--
 {
  inputs={
   bangberry,
   bangberry,
   bangberry,
  },
  output=bangtriberryjam
 },
 --bangnana jam--
 {
  inputs={
   bangtriberryjam,
   bangtriberryjam,
   bangtriberryjam,
  },
  output=bangnanaberryjam
 },
 {
  inputs={
   bangberry,
   bananaberry
  },
  output=bangnanaberryjam
 },
 --chaos jam--
 {
  inputs={
   bangberry,
   bigberry,
   badnanajam,
  },
  output=chaosjam
 },
 {
  inputs={
   chaosjam,
   chaosjam,
   badnanajam,
  },
  output=alphachaosjam
 },
 {
  inputs={
   alphachaosjam,
   alphachaosjam,
   badnanajam,
  },
  output=omegachaosjam
 },
 --badtri jam--
 {
  inputs={
   badjam,
   badjam,
   badjam,
  },
  output=badtrijam
 },
 --badnana jam--
 {
  inputs={
   badtrijam,
   badtrijam,
   badtrijam,
  },
  output=badnanajam
 },
 --bigbang jam--
 {
  inputs={
   bigberry,
   bangberry,
  },
  output=bigbangjam
 },
 --primordial jam--
 {
  inputs={
   bigbangjam,
   darknanajam,
   galactinanajam,
  },
  output=primordialjam
 },
}

-->8
-- upgrades --
function check_for_unlocks(scene)
 if(not primordialjam.quantity) primordialjam.quantity=0
 if (primordialjam.quantity >= 1) screen=new_gameover_screen()

 if cash_money[1]>=100 and not blueberry_bush.unlocked then
  blueberry_bush.unlocked=true
  add(screen.active_scenes[1].bushes, blueberry_bush)
 end

 if cash_money[2]>=10000 and not bananaberry_bush.unlocked then
  bananaberry_bush.unlocked=true
  add(screen.active_scenes[1].bushes, bananaberry_bush)
 end

 if cash_money[2]>=10 and not manberry_bush.unlocked then
  manberry_bush.unlocked=true
  add(screen.active_scenes[1].bushes, manberry_bush)
 end

 if cash_money[3]>=1 and not globerry_bush.unlocked then
  globerry_bush.unlocked=true
  add(screen.active_scenes[1].bushes, globerry_bush)
 end

 if cash_money[2]>=100 and not bigberry_bush.unlocked then
  bigberry_bush.unlocked=true
  add(screen.active_scenes[1].bushes, bigberry_bush)
 end

 if cash_money[4]>=1 and not bangberry_bush.unlocked then
  bangberry_bush.unlocked=true
  add(screen.active_scenes[1].bushes, bangberry_bush)
 end

 if cash_money[4]>=2500 and not darkberry_bush.unlocked then
  darkberry_bush.unlocked=true
  add(screen.active_scenes[1].bushes, darkberry_bush)
 end

 if cash_money[3]>=10000 and not galactiberry_bush.unlocked then
  galactiberry_bush.unlocked=true
  add(screen.active_scenes[1].bushes, galactiberry_bush)
 end

 if cash_money[1]==32767 and not accountant.unlocked then
  accountant.unlocked=true
  add(scene.available_upgrades, accountant)
 end

 if cash_money[2]==32767 and not banker.unlocked then
  banker.unlocked=true
  add(scene.available_upgrades, banker)
 end

 if cash_money[3]>=1 and not marketer.unlocked then
  marketer.unlocked=true
  add(scene.available_upgrades, marketer)
 end
 if cash_money[2]>=1 and not sales.unlocked then
  sales.unlocked=true
  add(scene.available_upgrades, sales)
 end

 if cash_money[4]>=1 and not ceo.unlocked then
  ceo.unlocked=true
  add(scene.available_upgrades, ceo)
 end

 if cash_money[3]==32767 and not blockchain.unlocked then
  blockchain.unlocked=true
  add(scene.available_upgrades, blockchain)
 end

 if cash_money[1]>=100 and not farmer.unlocked then
  farmer.unlocked=true
  add(scene.available_upgrades, farmer)
  screen.active_scenes[4]=screen.scenes[4]
  screen.active_scenes[4].unlocked=true
 end

 if cash_money[1]>=1000 and not cook.unlocked then
  cook.unlocked=true
  add(scene.available_upgrades, cook)
 end
end

cook={
 name="cook",
 description="automatically makes known jams",
 unlocked=false,
 price=1000,
 scale=1,
 quantity=0,
 max_quantity=32767,
 icon=189,
 countdown=0.0,
 update=function(scene)
  cook.countdown=increment(cook.countdown,1/30)
  if cook.countdown > global_cook_speed then
   cook.countdown=0.0
   for i=1,cook.quantity,1 do
    for recipe in all(known_good_recipes) do
    local can_cook=true
     if can_cook and has_ingredients(recipe) then
      spend_ingredients(recipe)
      gain_jam(recipe.output)
      can_cook=false
     end
    end
   end
  end
 end
}

farmer={
 name="farmer",
 description="automatically harvests berries",
 unlocked=false,
 price=100,
 scale=1,
 max_quantity=32767,
 icon=188,
 countdown=0.0,
 update=function(scene)
  farmer.countdown=increment(farmer.countdown,1/30)
  if farmer.countdown > global_harvest_speed then
   farmer.countdown=0.0
   harvest(screen.active_scenes[1], farmer.quantity)
  end
 end
}

accountant={
 name="accountant",
 description="converts "..cash_symbols[1].." into "..cash_symbols[2],
 unlocked=false,
 price=32767,
 scale=1,
 max_quantity=1,
 icon=173,
 on_purchase=function(scene)
  accountant_unlocked=true
 end
}

banker={
 name="banker",
 description="converts "..cash_symbols[2].." into "..cash_symbols[3],
 unlocked=false,
 price=32767,
 scale=2,
 max_quantity=1,
 icon=174,
 on_purchase=function(scene)
  banker_unlocked=true
 end
}

blockchain={
 name="blochchain",
 description="converts "..cash_symbols[3].." into "..cash_symbols[4],
 unlocked=false,
 price=32767,
 scale=3,
 max_quantity=1,
 icon=175,
 on_purchase=function(scene)
  blockchain_unlocked=true
 end
}

sales={
 name="sales person",
 description="increase the number of jams sold",
 unlocked=false,
 price=1,
 scale=2,
 max_quantity=32767,
 icon=191,
 on_purchase=function(scene)
  global_sale_volume=increment(global_sale_volume)
 end
}

marketer={
 name="marketer",
 description="increases rate of demand growth",
 unlocked=false,
 price=1,
 scale=3,
 max_quantity=32767,
 icon=190,
 on_purchase=function(scene)
  global_demand_rate_mod=increment(global_demand_rate_mod)
 end
}

ceo={
 name="ceo",
 description="increases prices of all jams",
 unlocked=false,
 price=1,
 scale=4,
 max_quantity=32767,
 icon=228,
 on_purchase=function(scene)
  global_marketing_efficiency=increment(global_marketing_efficiency, 0.1)
 end
}
__gfx__
00000000555555555555555555555555555555555555555555555555555555555555555555555555555555555555555500bbbbbbbbbbbbbbbbbbbbbbbbbbbb00
000000000628826006d11d600633326006000060067777600628d1600628776006d14460069aa96006777760067799600bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0
0070070006828860061111600633336006000060065775600688116006887c600611436006a9aa6006c77c60063795600bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0
00077000068882600611d16006323360060000600677776006821d6006827760061d446006aaa96006777760067799600bbbbbbbbbb333bbbbbbbbbb333bbbb0
000770006282888661d111166333323660000006677777766888111662887776611144466aa9aa9662881d1667dddd960bbbbbbbbb3333bbbbbbbbb3333bbbb0
007007006888828661111116633233366000000667dddd76628811d66882dd766d11dd4669aa9aa6688211166744ee960bbbbbbbbb38333bbbbbbbb38333bbb0
00000000682828266d11d1d662333326600000066777ee766882d1166288ee76611dee466a9aaa966288d1d66444ee460bbbbbbbb333338bbbbbbb333338bbb0
0000000006666660066666600666666006666660066666600666666006666660066666600666666006666660066666600bbbbb3333333333bbbbbb3833333bb0
0330033000144100044444400aaaaaa00eeeeee00aaaaaa0011111100077770000dddd0000111100000550000deeeeed0bbbb33338338338bbb3333338338bb0
000330000111111044777744aa7777aaee4444eeaa9999aa114444110cccccc00dd111d0011ddd1000555500deeddded0bbbb38333333333bb33333333333bb0
008888001111111147777774a777777ae444444ea999999a14444441cbbcccbcdd1ddd1d11d111d105655650dedeeded0bbb333338bbbbbbbb38333bbbbbbbb0
0888888011111111737777377c7777c7434444349599995942444424bbbcccbbd1dd1d1d1d11d1d155566555dededded0bb33333333bbbbbb333338bbbbbbbb0
08888880111111117777777777777777444444449999999944444444bbccccccd1d1dd1d1d1d11d155566555dedeeeed0bb38338338bbbbb33333333bbbbbbb0
08888880111111117dddddd77dddddd74dddddd49dddddd94dddddd4ccccbbccd1dd11dd1d11dd1105655650deeddddd0bb33333333bbbbb38338338bbbbbbb0
00888800011111107777eee77777eee74444eee49999eee94444eee40cccbbc00d1dddd001d1111000555500dddeee000bbbbbbbbbbbbbbb33333333bbbbbbb0
00088000001111000777eee00777eee00444eee00999eee00444eee00077770000d1dd00001d11000005500000dddee000bbbbbbbbbbbbbbbbbbbbbbbbbbbb00
000070005555555555555555bbbbbb3b55555555555555555555555555555555ddddd57777777777775dd5777775dddd5555555555dddddddddddd5555dddd55
000077000677776006777760b3bbbb3b06777760067777600677776006777760ddddd57777777777775dd5777775ddddd555555ddddddddddddddddddddddddd
0000777006cbcc6006cbcc603bbbb3bb06cbcc6006cbcc6006cbcc6006cbcc60ddddd57777777777775dd5777775ddddd555555ddddddddddddddddddddddddd
7777777706bbcc6006bbcc603bbb3bbb06bbcc6006bbcc6006bbcc6006bbcc60ddddd57777777777775dd5777775ddddd555555ddddddddddddddddddddddddd
777777776ccccbc6611d1d16bb3b3bbb6882828667777776611d828665114446ddddd57777777777775dd5777775dddddd5555dddddddddddddddddddddddddd
000077706bcbbbc66d11d116b33bbb3b6288288667dddd766d1128866115dd46ddddd57777777777775dd5777775dddddd5555dddddddddddddddddddddddddd
000077006777777661d111d6bbbbb3bb682888266777ee7661d188266511ee46ddddd57777777777775dd5777775dddddd5555dddddddddddddddddddddddddd
0000700006666660066666603bbbb3bb06666660066666600666666006666660ddddd57676767676765dd5767675dddddd5555dddddddddddddddddddddddddd
0000000000000000000555000000000000000000dd5555dddd5555dddddddddd5555555555555555555555555555555507777770555555550000000000004444
0003330000000000055555550003330000033300dd5555dddd5555dddddddddd067777600677de6006115160061151607ffffff75d5555d50004330000004444
0033330006600660055555550033330000333300dd5555dd555555555555555506cbcc6006cbdd6006511560065115600fcffcf051586515003a33000000aaaa
0038333006600660555555550033333000313330dd5555dd555555555555555506bbcc6006bced60061511600615116008ffff805d5885d500aa34300000aaaa
0333338006660666555555550333333003333310dd5555dd5555555555555555628844466bbcddd66882ddd66777ddd6f0eeee0f5155551504333a30000aaaaa
3333333366666666555555553333333333333333dd5555dddd5555dddddddddd6882dd466ccbede66288ede667ddede60eeeeee0550000553a33aa3400aaaaa0
3833833856565656055555503333333331331331dd5555dddd5555dddddddddd6288ee466777ded66882ded66777ded6eeeeeeee50000005aa33333a0aaaaa00
3333333366666666000055003333333333333333dd5555dddd5555dddddddddd06666660066666600666666006666660eeeeeeee50000005333333aaaaaa0000
55555555555555555555555500dddddddddddddddddddddddddddd00009999977777777777777777779999000066666666666666666666666666660055555555
06947860065d516006dede600dddddddddddddddddd444444444ddd009999997777777fffffffff7777999900667777776666666666666666666666006777760
06947860061ede6006eddd600dddddddd55555555dd4fffffff4ddd00999997777fffffffffffffff7779990067ffffff7665555666666666666666006cbcb60
06947860065d5d6006dded600dd5555555588826ddd48f8f8f84ddd009999977fffffffffffffffff7779990066fcffcf6665aa5777777666666666006bcbc60
6ed654a66ede1ed66dedddd60ddd628826882886ddd444444444ddd0099997778888888fff8888888f7779900668ffff86665aa7ffffff76655556606511ddd6
6ed3e4a6615d5d566eddede60ddd682886288826ddd4fffffff4ddd00999777f8fcccf88888fcccf8ff7779006f6eeee6f665555fcffcf6665aa56606151ede6
6edce9a66e1ede166dedded60ddd6888268828886dd41f1f1f14ddd0099977ff8fcccf8fff8fcccf8fff7790066eeeeee65555558ffff86665aa56606515ded6
0666666006666660066666600dd62855555555886dd444444444ddd0099777ff8fcccf8fff8fcccf8fff779006eeee777777666feeeeeef66555566006666660
5555555555555555555555550dd68886288268826dd4fffffff4ddd0099999ff8888888fff8888888fff999006eee7ffffff7665555eee655555555055555555
0656556006d1d16006dddd600dd6828682886886ddd49f9f9f94ddd0099999ffffffffff9fffffffffff9990066666fcffcf6665aa5eeee56666665006777760
06555560061d1d6006dddd600ddd66668882666dddd444444444ddd0099999fffffffff99fffffffffff99900666668ffff86665aa5eeee56666665006cbcb60
0655656006d1d16006dddd600ddddd62828886ddddd4f6fff6f4ddd0099999fffff88ffffff88ffffff9999006666f6eeee6f665555666666666666006bcbc60
655555566d1d1d166dddddd60ddddd68888286ddddd4616f6864ddd00999999fffff88888888ffffff999990066666eeeeee655555555666666666606288ddd6
6565565661d1d1d66dddddd60ddddd68282826ddddd4666f6664ddd009999999fff8888888888fff9999999006666eeeeeeee56666665666666666606828ede6
655555566d1d1d166dddddd60dddddd666666dddddd444444444ddd00999999999fffffffffffff99999999006666eeeeeeee56666665666666666606282ded6
06666660066666600666666000dddddddddddddddddddddddddddd00009999999eeeffffffffeee9999999000066666666666666666666666666660006666660
55555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
0611116006ad5a600677446000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006444460
06111160061ede600657436000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006c44c60
06111160065dad600677446000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006444460
611111166ede1ed6677744460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006288ddd6
6111111661ad5d5667dddd460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006828ede6
611111166e1eaea66777ee460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006282ded6
06666660066666600666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006666660
55555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
0651de600628de600699de6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006777760
0611dd600688dd600659dd6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006cbcb60
0611ed600688ed600699ed6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006bcbc60
6115ddd66882ddd66999ddd60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006777ddd6
6511ede66288ede669ddede600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000067ddede6
6115ded66882ded66999ded60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006777ded6
06666660066666600666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006666660
00000000007777777777777000000000000000000077777777777770000000000000000000777777777777700000000000000000000000000000000000000000
00000000777777777777777700000000000000007777777777777777000000000000000077777777777777770000000000000000000000000000000000000000
00000077777777777777777770000000000000777777777777777777700000000000007777777777777777777000000000000000000000000000000000000000
0000007777777fffffffff77770000000000007777777fffffffff77770000000000007777777fffffffff777700000000000000000000000000000000000000
000007777fffffffffffffff77700000000007777fffffffffffffff77700000000007777fffffffffffffff7770000000000000000000000000000000000000
0000077fffffffffffffffff777000000000077fffffffffffffffff777000000000077fffffffffffffffff7770000000000000000000000000000000000000
00007778888888fff8888888f777000000007778888888fff8888888f777000000007778888888fff8888888f777000000000000000000000000000000000000
000777f8fcccf88888fcccf8ff777000000777f8fffff88888fffff8ff777000000777f8fffff88888fffff8ff77700000000000000000000000000000000000
00077ff8fcccf8fff8fcccf8fff7700000077ff8fcccf8fff8fcccf8fff7700000077ff8fffff8fff8fffff8fff7700000000000000000000000000000000000
00777ff8fcccf8fff8fcccf8fff7700000777ff8fffff8fff8fffff8fff7700000777ff8fffff8fff8fffff8fff7700000000000000000000000000000000000
00000ff8888888fff8888888fff0000000000ff8888888fff8888888fff0000000000ff8888888fff8888888fff0000000000000000000000000000000000000
00000ffffffffff9fffffffffff0000000000ffffffffff9fffffffffff0000000000ffffffffff9fffffffffff0000000000000000000000000000000000000
00000fffffffff99fffffffffff0000000000fffffffff99fffffffffff0000000000fffffffff99fffffffffff0000000000000000000000000000000000000
00000fffff88ffffff88ffffff00000000000fffff88ffffff88ffffff00000000000fffff88ffffff88ffffff00000000000000000000000000000000000000
000000fffff88888888ffffff0000000000000fffff88888888ffffff0000000000000fffff88888888ffffff000000000000000000000000000000000000000
0000000fff8888888888fff0000000000000000fff8888888888fff0000000000000000fff8888888888fff00000000000000000000000000000000000000000
000000000fffffffffffff0000000000000000000fffffffffffff0000000000000000000fffffffffffff00000000005555555500555000005555005555b000
00000000eeeffffffffeee000000000000000000eeeffffffffeee000000000000000000eeeffffffffeee00000000000613476000c4c000009999005aa5bbb0
00000022eeeeeeeeeeeeeee20000000000000022eeeeeeeeeeeeeee20000000000000022eeeeeeeeeeeeeee200000000068269603044400000c99c005a5555b0
000000222eeeeeeeeeeee22220000000000000222eeeeeeeeeeee22220000000000000222eeeeeeeeeeee2222000000006a5c26034585470004444005555a5bb
000002222222eeeeee22222222e00000000002222222eeeeee22222222e00000000002222222eeeeee22222222e000006cdef1a60058507034999943bb5a5555
0000e22222222222222222222eee00000000e22222222222222222222eee00000000e22222222222222222222eee00006ab3d6e600111077395555930b5555a5
0000ee2222222222222222222eeee0000000ee2222222222222222222eeee0000000ee2222222222222222222eeee0006b9dae8600111007005555000bbb5aa5
0000eeee22222222223322222eeee0000000eeee22222222223322222eeee0000000eeee22222222223322222eeee000066666600550550705555550000b5555
0fffeeee22222222333222222eeeeff00fffeeee22222222333222222eeeeff00fffeeee22222222333222222eeeeff000ffff00000770000007777000aaaa00
ffffeeee22222223322222222eeeefffffffeeee22222223322222222eeeefffffffeeee22222223322222222eeeefffffffffff007777000077ff700aaffa00
ffffeeeee2222888888222222eeeefffffffeeeee2222888888222222eeeefffffffeeeee2222888888222222eeeefff00c99c0500777700007cfc700acfca00
0fffeeeee2228888888882222eeeeff00fffeeeee2228888888882222eeeeff00fffeeeee2228888888882222eeeeff00044445500599500007fff700afffa00
0000eeeee222888888888222eeeee0000000eeeee222888888888222eeeee0000000eeeee222888888888222eeeee0000049940500999905302eee2002888203
0000eeeee222888888888222eeee00000000eeeee222888888888222eeee00000000eeeee222888888888222eeee000009ffff95897777953fe222eff82228f3
00000eeee222288888882222eee0000000000eeee222288888882222eee0000000000eeee222288888882222eee0000000ffff050077770000e232e0082b2800
00000eeee222228888822222eee0000000000eeee222228888822222eee0000000000eeee222228888822222eee0000000ffff050077770000e282e008282800
00000000000000000000000000000000888878874444999999999999999999999999444411111111222222223333333344444444555555556666666677777777
00000000000000000000000000000000878888884449999999999999999999999999944411111111222222223333333344444444555555556666666677777777
00000000000000000000000000000000888888884499999999999999999999999999994411111111222222223333333344444444555555556666666677777777
00000000000000000000000000000000887887884449999999999999999999999999944411111111222222223333333344444444555555556666666677777777
00000000000000000000000000000000888888884444444444444444444444444444444411111111222222223333333344444444555555556666666677777777
00000000000000000000000000000000878878874ffffffffffffffffffffffffffffff411111111222222223333333344444444555555556666666677777777
00000000000000000000000000000000888888884ffffffffffffffffffffffffffffff411111111222222223333333344444444555555556666666677777777
00000000000000000000000000000000887888784ff44f444f444f444ff444f444f444f411111111222222223333333344444444555555556666666677777777
00000000000000000000000000000000dddddddd4f4fff4f4f4f4f444fff4ff4f4f444f48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
00000000000000000000000000000000dddddddd4f4fff44ff444f4f4fff4ff444f4f4f48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
00000000000000000000000000000000dddddddd4f4f4f4f4f4f4f4f4fff4ff4f4f4f4f48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
00000000000000000000000000000000dddddddd4f444f4f4f4f4f4f4ff44ff4f4f4f4f48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
00000000000000000000000000000000dddddddd4ffffffffffffffffffffffffffffff48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
00000000000000000000000000000000dddddddd4ffffffffffffffffffffffffffffff48888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
00000000000000000000000000000000dddddddd444444444444444444444444444444448888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
00000000000000000000000000000000dddddddd999999999999999999999999999999998888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeeeffffffff
00000000000000000000000000000000000444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000044ff400003330000033300000331100003550000033300000000000000000000000000000000000000000000000000
000000000000000000000000000000000041f140003333000033330000333110003355000033ee00000000000000000000000000000000000000000000000000
00000000000000000000000000000000004fff4000333770003dd33000333330003333300033ee30000000000000000000000000000000000000000000000000
000000000000000000000000000000009056d65003333cb0033dd33003333330055333300ee33330000000000000000000000000000000000000000000000000
000000000000000000000000000000009f55d55fccc333333333333331133333355333333ee33333000000000000000000000000000000000000000000000000
0000000000000000000000000000000000555550bcc333cbdd3333dd31133311333333553333ee33000000000000000000000000000000000000000000000000
000000000000000000000000000000000055d550bbc333bbdd3333dd33333311333333553333ee33000000000000000000000000000000000000000000000000
__label__
444444444444444444444444444444444444444444444444444444444444444755555555555555557fffffff5555555555555555ffffffffffffffffffffffff
477477747774777474747774777477747774747444447774777477744444444755555555555555557fffffff5555555555555555ffffffffffffffffffffffff
7444474474747474747474747444747474747474444447447474777444444447ff662288882266ff7fffffffff662288882266ffffffffffffffffffffffffff
7774474477447774747477447744774477447774444447447774747444444447ff662288882266ff7fffffffff662288882266ffffffffffffffffffffffffff
4474474474747474777474747444747474744474444447447474747444444447ff668822888866ff7fffffffff668822888866ffffffffffffffffffffffffff
7744474474747474777477747774747474747774444477447474747444444447ff668822888866ff7fffffffff668822888866ffffffffffffffffffffffffff
4444444444444444444444444444444444444444444444444444444444444447ff668888882266ff7fffffffff668888882266ffffffffffffffffffffffffff
4444444444444444444444444444444444444444444444444444444444444447ff668888882266ff7fffffffff668888882266ffffffffffffffffffffffffff
444444449999999944449999999999999999999999994444999999994444444766228822888888667fffffff6622882288888866ffffffffffffffffffffffff
444444449999999944499999999999999999999999999444999999994444444766228822888888667fffffff6622882288888866ffffffffffffffffffffffff
444444449999999944999999999999999999999999999944999999994444444766888888882288667fffffff6688888888228866ffffffffffffffffffffffff
444444449999999944499999999999999999999999999444999999994444444766888888882288667fffffff6688888888228866ffffffffffffffffffffffff
444444449999999944444444444444444444444444444444999999994444444766882288228822667fffffff6688228822882266ffffffffffffffffffffffff
44444444999999994ffffffffffffffffffffffffffffff4999999994444444766882288228822667fffffff6688228822882266ffffffffffffffffffffffff
44444444999999994ffffffffffffffffffffffffffffff49999999944444447ff666666666666ff7fffffffff666666666666ffffffffffffffffffffffffff
44444444999999994ff44f444f444f444ff444f444f444f49999999944444447ff666666666666ff7fffffffff666666666666ffffffffffffffffffffffffff
44444444999999994f4fff4f4f4f4f444fff4ff4f4f444f4999999994444444777777777777777777fffffff77ffffffffffffffffffffffffffffffffffffff
44444444999999994f4fff44ff444f4f4fff4ff444f4f4f49999999944444444f7fffffffffffffffffffffff7ffffffffffffffffffffffffffffffffffffff
44444444999999994f4f4f4f4f4f4f4f4fff4ff4f4f4f4f49999999944444444f7fffffffffffffffffffffff7ffffffffffffffffffffffffffffffffffffff
44444444999999994f444f4f4f4f4f4f4ff44ff4f4f4f4f49999999944444444f7fffffffffffffffffffffff7ffffffffffffffffffffffffffffffffffffff
44444444999999994ffffffffffffffffffffffffffffff49999999944444444777fffffffffffffffffffff777fffffffffffffffffffffffffffffffffffff
44444444999999994ffffffffffffffffffffffffffffff49999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999444444444444444444444444444444449999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999999999999999999999999999999999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999999999997777777777777999999999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999999999777777777777777799999999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999999977777777777777777779999999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444449999999999999999997777777fffffffff7777999999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444999999999999999997777fffffffffffffff77799999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444449999999999999999977fffffffffffffffff77799999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999997778888888fff8888888f7779999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444999999999999999777f8fcccf88888fcccf8ff777999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999977ff8fcccf8fff8fcccf8fff77999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999777ff8fcccf8fff8fcccf8fff77999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999999ff8888888fff8888888fff99999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999999ffffffffff9fffffffffff99999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999999fffffffff99fffffffffff99999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999999fffff88ffffff88ffffff999999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444999999999999999999fffff88888888ffffff9999999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444449999999999999999999fff8888888888fff999999999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444999999999999999999999fffffffffffff9999999999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999999999eeeffffffffeee9999999999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999999922eeeeeeeeeeeeeee299999999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444999999999999999999222eeeeeeeeeeee22229999999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444999999999999999992222222eeeeee22222222e99999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444449999999999999999e22222222222222222222eee9999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444449999999999999999ee2222222222222222222eeee999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444449999999999999999eeee22222222223322222eeee999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444449999999999999fffeeee22222222333222222eeeeff9999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444999999999999ffffeeee22222223322222222eeeefff999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444999999999999ffffeeeee2222888888222222eeeefff999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444449999999999999fffeeeee2228888888882222eeeeff9999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444449999999999999999eeeee222888888888222eeeee999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444449999999999999999eeeee222888888888222eeee9999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999999eeee222288888882222eee99999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444499999999999999999eeee222228888822222eee99999999944444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444444444444444444444444444444444444444444444444444444444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444444444444444444444444444444444444444444444444444444444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444444444444444444444444444444444444444444444444444444444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444444444444444444444444444444444444444444444444444444444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444444444444444444444444444444444444444444444444444444444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444444444444444444444444444444444444444444444444444444444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444444444444444444444444444444444444444444444444444444444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444444444444444444444444444444444444444444444444444444444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444f77f777f7fff777fffff777f777f777ff77f777fffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444447fff7f7f7fff7fffffff7f7f7f7ff7ff7fff7ffff7ffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444777f777f7fff77ffffff777f77fff7ff7fff77ffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ff7f7f7f7fff7fffffff7fff7f7ff7ff7fff7ffff7ffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444477ff7f7f777f777fffff7fff7f7f777ff77f777fffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffff7777777f777fffff777f777f777f777f44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffff7fffffff7f7f7f7f7f7f7f44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffff7777777f777fffff777f777f777f777f44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffff7fffffff7fffff7fff7f7f7f44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffff7777777f777ff7ff777fff7fff7f777f44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
4444444477ff777f777f777f77ff77ffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444447f7f7fff777f7f7f7f7f7f7ff7ffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444447f7f77ff7f7f777f7f7f7f7fffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
444444447f7f7fff7f7f7f7f7f7f7f7ff7ffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444777f777f7f7f7f7f7f7f777fffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffff77ffffff77ff7f7f777f777f7f7f44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444fffffffffffffffffffff7fffffff7ff7f7f7f7f7f7ff7ff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444fffffffffffffffffffff7fffffff7ff777f777f777f777f44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444fffffffffffffffffffff7fffffff7ffff7fff7fff7ff7ff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffff777ff7ff777fff7fff7fff7f7f7f44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444ffffffffffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44bbbbbbbbbbbbbbbbbbbbbbbbbbbb4444dddddddddddddddddddddddddddd477777777777777777777777777777777774444444444444444444444444444444
4bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb44dddddddddddddddddd444444444ddd749999997777777fffffffff77779999474444444444444444444444444444444
4bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb44dddddddd55555555dd4fffffff4ddd74999997777fffffffffffffff777999474444444444444444444444444444444
4bbbbbbbbbb333bbbbbbbbbb333bbbb44dd5555555588826ddd48f8f8f84ddd749999977fffffffffffffffff777999474444444444444444444444444444444
4bbbbbbbbb3333bbbbbbbbb3333bbbb44ddd628826882886ddd444444444ddd7499997778888888fff8888888f77799474444444444444444444444444444444
4bbbbbbbbb38333bbbbbbbb38333bbb44ddd682886288826ddd4fffffff4ddd74999777f8fcccf88888fcccf8ff7779474444444444444444444444444444444
4bbbbbbbb333338bbbbbbb333338bbb44ddd6888268828886dd41f1f1f14ddd7499977ff8fcccf8fff8fcccf8fff779474444444444444444444444444444444
4bbbbb3333333333bbbbbb3833333bb44dd62855555555886dd444444444ddd7499777ff8fcccf8fff8fcccf8fff779474444444444444444444444444444444
4bbbb33338338338bbb3333338338bb44dd68886288268826dd4fffffff4ddd7499999ff8888888fff8888888fff999474444444444444444444444444444444
4bbbb38333333333bb33333333333bb44dd6828682886886ddd49f9f9f94ddd7499999ffffffffff9fffffffffff999474444444444444444444444444444444
4bbb333338bbbbbbbb38333bbbbbbbb44ddd66668882666dddd444444444ddd7499999fffffffff99fffffffffff999474444444444444444444444444444444
4bb33333333bbbbbb333338bbbbbbbb44ddddd62828886ddddd4f6fff6f4ddd7499999fffff88ffffff88ffffff9999474444444444444444444444444444444
4bb38338338bbbbb33333333bbbbbbb44ddddd68888286ddddd4616f6864ddd74999999fffff88888888ffffff99999474444444444444444444444444444444
4bb33333333bbbbb38338338bbbbbbb44ddddd68282826ddddd4666f6664ddd749999999fff8888888888fff9999999474444444444444444444444444444444
4bbbbbbbbbbbbbbb33333333bbbbbbb44dddddd666666dddddd444444444ddd74999999999fffffffffffff99999999474444444444444444444444444444444
44bbbbbbbbbbbbbbbbbbbbbbbbbbbb4444dddddddddddddddddddddddddddd477777777777777777777777777777777774444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
77777774777444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444447444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
77777774777444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444744444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
77777774777444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444

__map__
ddddddddddddddccdfdfdfdfdfdfdfdfd4d4d4d4d4d4d4ccdfdfdfdfdfdfdfdfccccccccccccccccdfdfdfdfdfdfdfdfcecececececececccececececececece00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddccdfdfdfdfdfdfdfdf28292a292a292bccdfdfdfdfdfdfdfdfccdac5c6c7c8daccdfdfdfdfdfdfdfdfcecececececececccececececececece00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddccdfdfdfdfdfdfdfdf2e2c2f2c2f2c2dccdfdfdfdfdfdfdfdfccdad5d6d7d8daccdfdfdfdfdfdfdfdfcecececececececccececececececece00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddccdfdfdfdfdfdfdfdfd4cd373637cdd4ccdfdfdfdfdfdfdfdfccdadadadadadaccdfdfdfdfdfdfdfdfcecececececececccececececececece00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddccdfdfdfdfdfdfdfdfd4d4d435d4d4d4ccdfdfdfdfdfdfdfdfccdadadadadadaccdfdfdfdfdfdfdfdfcecececececececccececececececece00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddccdfdfdfdfdfdfdfdfd4d4d435d4d4d4ccdfdfdfdfdfdfdfdfccdadadadadadaccdfdfdfdfdfdfdfdfcecececececececccececececececece00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23232323232323ccdfdfdfdfdfdfdfdfd4d4d42cd4d4d4ccdfdfdfdfdfdfdfdfccdadadadadadaccdfdfdfdfdfdfdfdfcecececececececccececececececece00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23232323232323ccdfdfdfdfdfdfdfdfd4d4d4d4d4d4d4ccdfdfdfdfdfdfdfdfccccccccccccccccdfdfdfdfdfdfdfdfcecececececececccececececececece00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23232323232323ccdfdfdfdfdfdfdfdfd4d4d4d4d4d4d4ccdfdfdfdfdfdfdfdfccdfdfdfdfdfdfccdfdfdfdfdfdfdfdfcecececececececccececececececece00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23232323232323ccdfdfdfdfdfdfdfdfcdcdcdcdcdcdcdccdfdfdfdfdfdfdfdfccdfdfdfdfdfdfccdfdfdfdfdfdfdfdfcecececececececccececececececece00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23232323232323ccdfdfdfdfdfdfdfdfcdcdcdcdcdcdcdccdfdfdfdfdfdfdfdfccdfdfdfdfdfdfccdfdfdfdfdfdfdfdfcecececececececccececececececece00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23232323232323ccdfdfdfdfdfdfdfdfcdcdcdcdcdcdcdccdfdfdfdfdfdfdfdfccdfdfdfdfdfdfccdfdfdfdfdfdfdfdfcecececececececccececececececece00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000000000000000000000000000000000000000e050150501c05021050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000f150000000830009300101000a4000f400114001d4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000315000000000000010001100011000210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002201000000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002975025750297502c75029750257503070025750247002d75024700247002c750247002f7502b7502f750247002f7502d75024700247002f7502d7502d7502a750247002470024700247002470024700
