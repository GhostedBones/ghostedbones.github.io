pico-8 cartridge // http://www.pico-8.com
version 33
__lua__


--[[
##chrysopoeia by benjamin_soule
##is the base for everything here
##thank you for playing my game!

## characters and story are mine
Spooky the Ghost
Hilda the Skeleton
Wayne the Bat
Charlotte the Spider
Bob the Blob
Noodle the Snake
Adenoid the Wizard
Digby the Dog
]]


function _init()
	logs={}
 ents={}
 rain={}
 t=0
 sfx(26)

 -- vars
 days=1
 gold=4
 items={}
 customers=0

 -- forest
 herb={}
 for x=0,15 do for y=0,15 do
  if mget(16+x,y)==69 then
   add(herb,{x=x*8,y=y*8})
  end
 end end

 -- merchant
 merchant={}
 merchant_pool={}
 for i=0,7 do
  add(merchant_pool,32+i)
 end

 -- equipment
 shelves={{nil,1,nil,2,3}}
 stock={}
 shelves={{1,2,3,4,5,6,7,8,9}}
 stock={1,2}
 recipes = {0,1,2}

 forest={}

 -- parse data
 al={}
 rdat={}
 for i=0,32 do
  o={cost={},res={}}
  a=o.cost
  x=48
  for k=0,8 do
	  n=mget(x,i)
	  if n==2 then
	   break
	  elseif n==134 then
	   a=o.res
	  else
	   add(a,n)
	  end
	  x+=1
	 end
	 if #o.cost>0 then
	  add(rdat,o)
	  if i>0 then add(al,i) end
	 else
	  break
	 end
 end

 -- val
 val=mke(0,60,60)
 val.dr=dr_val
 walk=0
 wface=0
 val.ldx=0
 val.brd=true
 val.ldy=0
 val.dy=0
 val.dy=0
 wflp=false
 --character talk
 vm=0
 vd=0
 vb=0
 va=0
 vh=0
 vn=0
 vc=0
 vs=0
 vw=0



 new_day()
 if jump_to then
  scn=0
  reset_scene()
  loop(control)
 else
  init_intro()
 end


end

function run_away(e)

 moveto(e,e.x,e.y+32,24)
 e.dr=function(e)
  spr(11,e.x,e.y)
  spr(27,e.x,e.y+14,1,1,t%8<4)
 end
 wait(24,kl,e)
 wait(24,unfreeze)
end


function nhv(n)
 local sum=0
 for k in all(items) do
  if n==k then sum+=1 end
 end
 return sum
end

function hv(n)
 return nhv(n)>0
end


function rand(k)
 return flr(rnd(k))
end


function end_game()
 fading=loop(fade)

end

function control(e)
 if freeze then return end
 if ending then
  freeze=true
  sfx(24)
  wait(40,end_game)
  return
 end


 val.dx=0
 val.dy=0
 act=nil
 wcol()
 if btn(0) then wmove(-1,0) end
 if btn(1) then wmove(1,0) end
 if btn(2) then wmove(0,-1) end
 if btn(3) then wmove(0,1) end

 -- walk_cycle
 if is_moving() then
  if t%4==0 then
  	walk=(walk+1)%4
	 end
	 if t%8== 0 then
	  bs=4
	  if pcol(val.x+4,val.y+4,3) then
	   bs+=2
	  end
	  sfx(bs+(t%4))
	 end
	else
	 walk=0
 end

 -- interact
 if btnp(4) then
  if act then
  	act.act(act)
  end

 end

end

function net_catch(e)
 walk=1

 if e.t%4 == 0 then

  val.dx,val.dy=-val.ldy,val.ldx
 end

 val.net=-e.t/20
 if e.t==20 then
  val.net = nil
  unfreeze()
  kl(e)
 end
end

function ending_screen(win)
 --pal()
 t=0
 tdy=0
 ens=function()
  rectfill(0,0,127,127,win and 3 or 8)
  if win then
   camera(-23,-40)
   talk("congratulations!",t,80,64)
   camera()
  else
   print("game over",46,60,7)
  end
  if t>40 and btnp(4) then
  -- reboot()
  end
 end


end

function fade(e)
 if e.light then
  e.t-=1.5
 end
 k=e.t/4
 for i=0,15 do
  pal(i,sget(16+i,24+k+i/16))
 end
 if k>5 and not e.light then
  e.light=true
  days+=1
  if ending then
   ending_screen(true)
 elseif days==100 then
   ending_screen(false)
  else
   new_day()
  end

 end
 if k<=0 then
  init_intro()
  fading=nil
  pal()
  kl(e)
 end

end


function new_day()

 -- reset
 scn=0
 reset_scene()
 val.x=60
 val.y=60
 walk=0
 wface=0
 val.dx=0
 val.dy=0


end

function init_intro()
 if days>1 then sfx(27) end
 tdy=0
 loop(nil,dr_intro)
end

function dr_intro(e)

 y=128-min(e.t/10,1)*48

 rectfill(0,y-1,127,y+30,7)
 rectfill(0,y,127,y+29,8)
 rectfill(0,y+31,127,y+31,1)

	print("12:00 pm ",54,y+2,14)

	by=y+9
	if not e.skip then
		camera(-1,-by)
		clip(0,by,128,y+56)
		t=-1
		talk("hELLO, THANKS FOR JOINING US TONIGHT AS WE PAY A VISIT TO THE midnight launderette.",e.t,126,13)
		clip()
		camera()
	end
	if e.skip then
	 e.t-=2
	 if e.t<0 then
	  kl(e)
		loop(control)

	 end
	elseif btnp(4) then
	 sfx(28)
	 e.skip=true
	 e.t=10
	end

end


function get_act()
 for e in all(ents) do
  if e.act then
   local x=e.x
   local y=e.y
   if e.rx then
    x+=e.rx
    y+=e.ry
   end
   dx=x-val.x-4
   dy=y-val.y-4
   if sqrt(dx*dx+dy*dy)<4 then
    return e
   end
  end
 end
 return nil
end

function is_moving()
 return val.dx!=0 or val.dy!=0
end

function wmove(dx,dy)
 local spd=1.5
 if hv(35) then spd+=1 end

 val.x+=dx*spd
 val.y+=dy*spd

	while wcol() do
	 val.x-=dx
	 val.y-=dy
	end
	val.dx=dx
	val.dy=dy


end

function wcol()
 a={0,0,0,7,7,0,7,7}
 for i=0,3 do
  local x=val.x+a[1+i*2]
  local y=val.y+a[2+i*2]
  if pcol(x,y,0) then return true end
 end


 for e in all(ents) do
  if e.rx then
  	dx=(e.x+e.rx)-(val.x+4)
 		dy=(e.y+e.ry)-(val.y+2)

 		function chk(lim)
 		 e.wn=abs(dx)+abs(dy)
 		 return abs(dx)< 4+e.rx+lim and abs(dy)< 4+e.ry+lim
 		end
 		if chk(6) and e.act then
 		 if not act or ( act.wn> e.wn ) then
 		  act=e
 		 end
 		end
 		if chk(0) then
 		 return true
 		end
  end
 end

 return false
end

function pcol(x,y,n)

 tl=mget(scn*16+x/8,y/8)
 return fget(tl,n)
end

function inc_sum(a,inc)
 if not sum then
  sum={0,0,0,0,0,0,0,0,0,0,0}
 end
 for i=1,9 do
  if a[i] then
   sum[a[i]]+=inc
  end
 end
 return sum
end

function reset_scene()
 ents={}
 add(ents,val)
 if fading then
 add(ents,fading)
 end


-------------characters and items ----------

--Spooky
	spooky=mke(137,5,20)
	spooky.brd=true
	spooky.act=act_spook
	spooky.szy=2
	spooky.rx=0
	spooky.ry=6
	spooky.float=true

--Towel
	towel=mke(4,13,25)
	towel.float=true
	towel.brd=true

--hilda
	e=mke(139,40,12)
	e.brd=true
	e.szy=2
	e.act=act_hilda
	e.rx=0
	e.ry=11

--plant
	plnt=mke(15,32,9)
	plnt.szy=2
	plnt.brd=true

--spray bottle
	spray=mke(6,49,18)
	spray.brd=true

--charolette spider
	leg1=mke(187,116,8)
	leg2=mke(187,115,11)
	leg3=mke(187,114,13)
	leg4=mke(187,104,8)
	leg5=mke(187,105,11)
	leg6=mke(187,106,13)
	e=mke(171,110,14)
	e.brd=true
	e.act=act_charl
	e.rx=0
	e.ry=11
	e.float=true

--Digby
	digby=mke(178,60,43)
	digby.brd=true
	digby.szx=2
	digby.act=act_dig
	digby.rx=3
	digby.ry=3

--Mike
	e=mke(138,78,36)
	e.brd=true
	e.szy=2
	e.act=act_mike
	e.rx=2
	e.ry=6

--baskets
	bask_f=mke(177,88,45)
	bask_f.brd=true
	bask_f2=mke(177,80,106)
	bask_f2.brd=true
	bask_e=mke(176,64,106)
	bask_e.brd=true

--Bob the blob
	blob=mke(135,52,77)
	blob.act=act_bob
	blob.rx=2
	blob.ry=3
	rotate=0
	blob.upd=function(blob)

	end
	blob.dr=function(blob)
		if t>0 then
			if t%5==0 then rotate=(rotate+1)%4 end
		--animation of rotation
		sspr(56,64+rotate*8,8,8,52,77,8,8)
		end

	end

--detergent
	deter=mke(3,46,66)
	deter.brd=true

--cart
	cart=mke(198,105,90)
	cart.szy=4
	cart.szx=2
	cart.depth=1
	cart.brd=true

--Wayne the Bat
	e=mke(170,109,91)
	e.brd=true
	e.depth=1
	e.act=act_wayne
	e.rx=0
	e.ry=3

-- Adenoid
	 e=mke(12,32,99)
	 e.szy=2
	 e.brd=true
	 e.act=act_adenoid
	 e.rx=0
	 e.ry=3

--Iron
	iron=mke(5,11,95)
	iron.brd=true
--Ironing board
	board=mke(181,20,99)

--Noodle Snake
	e=mke(180,80,99)
	e.brd=true
	e.rx=0
	e.ry=3
	e.act=act_noodle
	e.float=true
	e.act=act_noodle


end

function item_get(fr)
	if it then kl(it) end
	if victory then kl(victory) end
	victory=mke(226,val.x,val.y-8)
	it=mke(fr, val.x,val.y-16)
	freeze=true
	name = ""
	it.ttl=50
	flash=0
	drift=0
	it.float=true
	it.brd=true
	it.depth=2
	val.depth=3
	val.it=fr
	if fr==7     then name="hedgehog"
	elseif fr==2 then name="basket"
	elseif fr==23 then name="webs"
	elseif fr==6 then name="spray bottle"
	elseif fr==9 then name="bucket"
	elseif fr==3 then name="detergent"
	elseif fr==5 then name="iron"
	elseif fr==4 then name="  towel"
	elseif fr==1 then name="hanger"

	end
	sfx(25)
	it.upd=function(it)
		it.ttl-=1
		if it.ttl<=0 then
			kl(it)
			kl(victory)
			val.depth=0
			unfreeze()
		end
	end

	it.dr=function(it)
		flash+=0.5
		drift+=0.08
		victory.szx=2
		victory.szy=2
		victory.brd=true
		victory.depth=0
		print(name,val.x-10,val.y-20-drift,8+flash%2)
	end
end
function game_over()
	t=0
	tdy=0
	ens=function()
	  rectfill(0,0,127,127,12)
		camera(-23,-40)
		talk("thanks for playing!",t,80,64)
		camera()
	end
end
-----------------dialogue-------------------
function act_mike(e)

		function vm4()
			msg("i'm so ready for some sleep!!!",140,game_over)
		end
		function vm3()
			msg("awwww nooo, that should have been the first place i checked... oh well let's get home to bed!",174,vm4)
		end
	 function vm2()
		 msg("it's just a cheap hanger, there's got to be plenty in this launderette.",140)
		end
	 function vm1()
		 msg("alright, no worries, i'll see if i can find a spare.",140)
		 vm=1
		end

	if (val.it==1 and vm==1) then
		msg("it was under digby the whole time!",140,vm3)
	elseif vm==1 then
		msg("i could of swore i brought a hanger just for this reason... i can't remember where it is...",174,vm2)
	else
		--mike
		msg("hey hunny, i forgot the hanger for my dress shirt! we need to find one before we go home.",174,vm1)
	end

end

function act_dig(e)
	function vd_it()
		item_get(7)
	end
	function vd_it2()
		item_get(1)
		vd=2
		kl(digby)
		--Digby
			digby=mke(194,60,43)
			digby.brd=true
			digby.szx=2
			digby.act=act_dig
			digby.rx=3
			digby.ry=3
	end

	function vd3()
		msg("i love being a burrito! oops i was laying on something...",202,vd_it2)
		vd=2
	end
	function vd2()
			msg("aww, don't worry digs, i'll find you something soft to snuggle in.",140)
	end
	function vd1()
			msg("digby, what's that in your mouth?",140,vd_it)
			vd=1
	end

	if vd==2 then
		msg("let's never leave.",202)
	elseif (val.it==4 and vd==1) then
		msg("here digby, stand up real quick so i can wrap you up like a tortilla.",140,vd3)
	elseif vd==1 then
		msg("so cozy and warm in here... still i wish i had a soft blanket.",202,vd2)
	else
		msg("i'm so tired, this place just makes me so sleepy, i can barely hold this toy i just found.",202,vd1)
	end
end

function act_bob(e)
	function vb_it()
		item_get(3)
		vb=2
		kl(deter)
		bucket=mke(9,50,66)
		bucket.brd=true
		kl(e)

	end
	function vb5()
		msg("finally! here you can take all the spare detergent i found while i was in there",236,vb_it)
	end
	function vb4()
			msg("yup! you can come out now...",140,vb5)
	end
	function vb3()
		msg("oh... my... glob... you are not helping... i can't talk! i am so distressed!",236)
	end
	function vb2()
			msg("no not yet... do you know where i can find one?",140,vb3)
	end
	function vb1()
			msg("...uhh yeah right away.",140)
			vb=1
	end
	if vb==2 then
		msg("i think he fainted",140)
	elseif (val.it==9 and vb==1) then
		msg("is that a bucket i see? i really can't tell i'm incredibly dizzy.",236,vb4)
	elseif vb==1 then
		msg("do you have the bucket for me?",236,vb2)
	else
		msg("omg, please help! i need a bucket to fill up and hold my composure.",236,vb1)
	end
end

function act_adenoid(e)
	function va_it()
		item_get(5)
		va=2
		kl(iron)
	end
	function va8()
		msg("an iron huh? okay that's a good weapon i guess...",140,va_it)
	end
	function va7()
		msg("besides the warm fuzzy feeling you get from helping a poor old man, you will be rewarded with the iron and board next to me.",172,va8)
	end
	function va6()
		msg("hold up, what do i get in return?",140,va7)
	end
	function va5()
		msg("WHY DO YOU THINK I NEED THIS?",172)
	end
	function va4()
		msg("yeah well... you smell like you haven't washed your clothes in weeks.",140,va5)
	end
	function va3()
		msg("wow rude... EVERYONE NEEDS SOMETHING AROUND HERE...",140)
		va=1
	end
	function va2()
			msg("i need a bottle of laundry detergent before we talk anymore.",172,va3)
	end
	function va1()
		msg("no, actually i was hoping you worked here, i'm looking for a-",140,va2)
	end

	if va==2 then
		msg("what am i still doing here?",172,run_away(e))
	elseif (val.it==3 and va==1) then
		msg("ahh yes, that clean smell... with haste! give me that soap!",172,va6)
	elseif va==1 then
		msg("leave me be little one, i can smell the lack of detergent with you.",172,va4)
	else
	msg("little girl, do you work here?",172,va1)
	end
end

function act_hilda(e)
	function vh_it()
		item_get(6)
		vh=2
		kl(spray)
	end
	function vh11()
		kl(plnt)
		plnt=mke(14,32,9)
		plnt.szy=2
		plnt.brd=true

		msg("okay, this could work... here take the poison spray. keep it away from my family.", 142,vh_it)
	end
	function vh10()
		msg("whoa, wait for serious? okay act cool, be cool...", 142)
	end
	function vh9()
		msg("shhh... not now, too many eyes on us.",140,vh10)
	end
	function vh8()
		msg("anything that can stop this drooping plant and i'll trade you this poison spray.", 142)
		vh=1
	end
	function vh7()
		msg("like string or clips or glue? i dunno.",140,vh8)
	end
	function vh6()
		msg("oh whoops, okay i need something to hold it up until i can find the proper nutrition.", 142,vh7)
	end
	function vh5()
		msg("that's not water, that's some cleaning chemical stuff, you are definitely killing it.",140,vh6)
	end
	function vh4()
		msg("i'm trying to figure out how to take care of this life form next to me. it seems to dislike the water i've been spraying at it.", 142,vh5)
	end
	function vh3()
		msg("the ones in my closet don't read books.",140,vh4)
	end
	function vh2()
		msg("haven't you seen a skeleton before?", 142,vh3)
	end
	function vh1()
		msg("i don't know, i haven't figured it out yet.",140,vh2)
	end

	if vh==2 then
		msg("shut up, i keep reading the same line over and over because of you.",142)
	elseif (val.it==23 and vh==1)then
			msg("i have an idea, let me see your plant real quick",140,vh11)
	elseif vh==1 then
		msg("you got the goods?", 142,vh9)
	else
		msg("what are you looking at?", 142,vh1)
	end

end

function act_noodle(e)
	function vn_it()
		item_get(2)
		vn=2
		kl(bask_e)
	end
	function vn6()
		msg("all i heard was 'hedgehog' those are my favorite! gimmie! oh here you can have my spare basket too",206,vn_it)
	end
	function vn5()
		msg("hey, i'm hungry too but you don't hear my complaining.",140)
	end
	function vn4()
		msg("lisssssten, i don't want any trouble, jusssst find me one of your ssssnick sssnacksss and i'll be out of here to feed up elsewhere.",206)
		vn=1
	end
	function vn3()
		msg("you better not eat my hubby or i'll turn you into an ugly scarf!",140,vn4)
	end
	function vn2()
		msg("i need more than a sssssssnick sssssssnack like you but that man over there looks like a full meal.",206,vn3)
	end
	function vn1()
		msg("yeah, there's no snick snack vending machines in here, just don't eat your tail!",140,vn2)
	end

	if vn==2 then
		msg("i'll leave soon it's just raining right now....",206)
	elseif (val.it==7 and vn==1) then
		msg("i found this anti-static dryer thing that's shaped like a hedgehog, will that do?",140,vn6)
	elseif vn==1 then
		msg("ssssssnick sssnaaaack?",206,vn5)
	else
		msg("i'm sssssoooooo hungry but this launderette doesn't have any food.",206,vn1)
	end
end


function act_charl(e)
	function vc_it()
		item_get(23)
		vc=2
	end

	function vc15()
		msg("that's what i thought",238,vc_it)
	end
	function vc14()
		msg("baskets are amazing and it's difficult for me to part with this...",140,vc15)
	end
	function vc13()
		msg("what's that?... you were mubling, i didn't hear you.",238,vc14)
	end
	function vc12()
		msg("basketsarenotsillyimsorryitakeitbackpleasegivemewebabilities",140,vc13)
	end
	function vc11()
		msg("baskets are not silly, take that back or you'll get nothing!",238,vc12)
	end
	function vc10()
		msg("fingertips?! that makes absolutely no sends, of course i'll take it!",140)
	end
	function vc9()
		msg("whoa, easy there nerd. do you want to shoot webs out your fingertips or not?",238,vc10)
	end
	function vc8()
		msg("peter parker made those web shooters himself! he never had that power imbued in-",140,vc9)
	end
	function vc7()
		msg("yeah, wouldn't you like to shoot webs from your hands?",238,vc8)
	end
	function vc6()
		msg("spider powers? like spider-man?",140,vc7)
	end
	function vc5()
		msg("how about... spider powers?",238,vc6)
	end
	function vc4()
			msg("if you get me a basket, that you didn't steal, i'll give you something better...",238)
			vc=1
	end
	function vc3()
		msg("if i get you a basket can i have that hanger there?",140,vc4)
	end
	function vc2()
		msg("you don't want these lame hangers... the only quality thing they have here are these amazingly strong baskets, it holds better than my webs, it would be great for my babies.",238,vc3)
	end
	function vc1()
		msg("whoa, easy there spider. i just wanted to get one of those cheap hangers, that can't be worth much to you can it?",140,vc2)
	end

	if vc==2 then
		msg("i can't lay my eggs if you keep looking at me.",238)
	elseif (val.it==2 and vc==1) then
		msg("here's your silly basket, spider-powers now plzthxbye.",140,vc11)
	elseif vc==1 then
		msg("wait what's better than a hanger?.... i mean a lot of things are but you are so vague!",140,vc5)
	else
		msg("backup, this inventory belongs to the midnight launderette and i will protect it 'til my last dying breath!",238,vc1)
	end

end



function act_spook(e)

	function vs_it()
		item_get(4)
		vs=2
		kl(towel)
		kl(spooky)
		--Spooky
			spooky=mke(136,5,20)
			spooky.brd=true
			spooky.act=act_spook
			spooky.szy=2
			spooky.rx=0
			spooky.ry=6
			spooky.float=true
	end
	function vs10()
		msg("this is why i don't talk to people... whatever take your towel.",234,vs_it)
	end
	function vs9()
		msg("i hope that's not your new catch phrase.",140,vs10)
	end
	function vs8()
		msg("haha i'm joking, keep your sheets white, i'll find you an iron hold on.",140)
	end
	function vs7()
		msg("awww what nooo... ghosts are always- that's a thing for- you can't-",234,vs8)
	end
	function vs6()
		msg("hey that's my line!",140,vs7)
	end
	function vs5()
		msg("trade hmm? okay give me an iron and i'll give you my spooky towel.",234)
		vs=1
	end
	function vs4()
		msg("nope, looks comfy though, i'll trade you for it.",140,vs5)
	end
	function vs3()
		msg("my usual white sheets have so many wrinkles i need to iron it out, all i have left is this fuzzy blue towel... it's not spooky looking at all is it?",234,vs4)
	end
	function vs2()
		msg("honestly, i noticed your floating towel first!",140,vs3)
	end
	function vs1()
		msg("holy macaroni don't scare me!... i didn't think you could see me...",234,vs2)
	end

	if vs==2 then
		msg("....................",234)
	elseif (val.it==5 and vs==1) then
		msg("it's ironing time!",234,vs9)
	elseif vs==1 then
		msg("boo!!!!!!!!!!!!!",234,vs6)
	else
		msg("boo!!!!!!!!!!!!!!",140,vs1)
	end
end

function act_wayne()
	function vw_it()
		item_get(9)
		vw=2
	end

	function vw19()
		msg("no, it was painful. here is your bright red bucket.",204,vw_it)
	end

	function vw18()
		msg("yes, did you like it?",140,vw19)
	end

	function vw17()
		msg("was that a pun because i sleep like this?",204,vw18)
	end

	function vw16()
		msg("well turn that frown upside down because i got this fair and square!",140,vw17)
	end


	function vw15()
		msg("no, stop pesking me, i'll get it eventually.",140)
	end

	function vw14()
		msg("well do you have it?",204,vw15)
	end

	function vw13()
		msg("you have to stop saying things like that",140,vw14)
	end


	function vw12()
		msg("for you miss, only the reddest",204)
		vw=1
	end

	function vw11()
		msg("deal, but it better be the reddest bucket i ever laid eyes on.",140,vw12)
	end

	function vw10()
		msg("i'll give you a red bucket in return...",204,vw11)
	end

	function vw9()
		msg("hmmm i dunno, you seem super suspect.",140,vw10)
	end

	function vw8()
		msg("haha oh no dear miss, this poison is for research purpose only, i assure you.",204,vw9)
	end

	function vw7()
		msg("are you threating me? i feel like a vampire is threatening me.",140,vw8)
	end

	function vw6()
		msg("that, my dear, is drowning. it is quicker than poison.",204,vw7)
	end

	function vw5()
		msg("oh yeah? what about water?",140,vw6)
	end

	function vw4()
		msg("what most don't realize is technically anything is poison in high enough quantities.",204,vw5)
	end

	function vw3()
		msg("well you are a strange little bat aren't you?",140,vw4)
	end

	function vw2()
		msg("i ask it, to everyone, every day.",204,vw3)
	end

	function vw1()
		msg("now there's a question you don't get asked every day.",140,vw2)
	end

	if vw==2 then
		msg("hahahaha... oh you're still here? ...",204)
	elseif (val.it==6 and vw==1)then
		msg("i frown upon thievery.",204,vw16)
	elseif vw==1 then
		msg("there's a face of someone with poison!",204,vw13)
	else
		msg("good evening miss, would you perchance happen to have poison on you?",204,vw1)
	end
end


function border(f,a,b,c)
 apal(1)
 camera(0,1)
 f(a,b,c)
 camera(1,0)
 f(a,b,c)
 camera(0,-1)
 f(a,b,c)
 camera(-1,0)
 f(a,b,c)
 pal()
 camera()
 f(a,b,c)
end


function unfreeze()
 freeze=false
end


function init_load()
  freeze=true
 	reset_pos()
 	--loop(load_wagon,dr_load)
end

function reset_pos()
 wx=0
 wy=0
 ws=0
end
function give(n,fx,fy)
 sfx(17)
 local a,b=seek_ing(nil)
 if not a then return end
 x,y=get_shelf_pos(a,b)

 if n==10 then
  ending=true
 end

 local e=mke(n,fx,fy)
 e.jump=40
 e.depth=0
 function f()
  sfx(4)
  kl(e)
  shelves[a+1][b+1]=n
 end
 moveto(e,x,y,20,f)

end

function seek_ing(n,rmv)
 a=0
 for sh in all(shelves) do
  for b=0,8 do
   if sh[b+1]==n then
    if rmv then sh[b+1]=nil end
    return a,b
   end
  end
  a+=1
 end
 return nil,nil
end

function get_shelf_pos(a,b)
 	return a*40+16+(b%3)*8, 16+flr(b/3)*8
end

function wait(t,f,a,b,c,d)
 e=mke(-1,0,0)
 e.life=t
 e.nxt=function() f(a,b,c,d) end
end

function can_pay(a)
 sum=nil
 for sh in all(shelves) do
  inc_sum(sh,1)
 end
 inc_sum(a,-1)

 local k=0
 for n in all(sum) do
  if n<0 then
   return false
  end
  k+=1
 end
 return true
end

function draw_rec(ri,x,y)

 map(7,16,x,y,5,5)
 local o=rdat[ri+1]

 function ings(a,by)
  local ki=0
  local ec=10
  if #a>=4 then ec=6 end
	 for n in all(a) do
	  spr(n,x+17+ki*ec-#a*flr(ec/2),by)
	  ki+=1
	 end
 end

 if o.cost[1]!=48 then
	 ings(o.cost,8+y)
	 spr(96,x+12,y+16)
	 ings(o.res,24+y)
 else
  ings(o.cost,16+y)
 end

end

function any_but()
 for i=0,5 do
  if btn(i) then return true end
 end
 return false
end

function msg(str,prt,nxt)

 port=prt or 140
 nxt=nxt or unfreeze
 freeze=true
 ms=mke(-1,0,0)
 tdy=0

 ms.upd=function(ms)

  if price then
   if btnp(0) or btnp(1) then
    choice=1-choice
    sfx(9)
   end
   if btnp(4) and ms.t>1 then
    kl(ms)
    if choice==0 then
     pay_gold(price,seller,buy_stuff)
	    sfx(15)
    else
     sfx(16)
     unfreeze()
    end
    price=nil
   end

  elseif any_but() then
   if ms.t>= #str then
    kl(ms)
    nxt()
   else
    ms.t+=2
   end
  end


 end
 ms.dr=function(ms)
	 ms.t-=0.5
  rectfill(7,107,120,124,7)
  rectfill(8,108,119,123,13)
		spr(port,8,108,2,2)

		camera(-26,-110)
		clip(9,109,110,14)
		talk(str,ms.t,94,6)
		clip()
		camera()

		if price and ms.t>10 then
			for i=0,1 do
			 txt=i==0 and "yes" or "no"
			 bx=48+i*36
				print(txt,bx,117, 7)
				if choice==i then
				 spr(49,bx-8,117)
				end
			end
		end

 end
 ms.depth=2

end


function dr_cauldron(e)
 camera(-e.x,-e.y)
 sspr(88,24,16,8,0,10)
 dx=0
 if e.recipe then dx=-16 end
 sspr(88+dx,16,16,8,0,2)
 camera()
end

function kl(e)
 del(ents,e)
 if e.nxt then e.nxt(e) end
end


function loop(f,dr)
 local e=mke(-1,0,0)
 e.upd=f
 e.dr=dr
 e.depth=2
 return e
end


function dr_val(e)
 ddy=0
 if pcol(e.x+4,e.y+4,1) then
  ddy=-4
 end
	camera(-e.x,ddy-e.y)
	-- shade
	--for x=0,8 do
	 --for y=5,9 do
	 -- n=pget(x,y)
	 -- pset(x,y,shd(n,0))
	-- end
	--end

 -- body
 if is_moving() then
	 wface=0
	 wflp=val.dx==-1
	 if val.dy<0 then wface=1 end
	 if val.dx!=0 then wface=2 end
	 val.ldx=val.dx
	 val.ldy=val.dy
	 val.depth=0
 end
 local dy=walk%2
 sspr(0+walk*12,64+wface*8,12,8,-2,-dy,12,8,wflp)

 -- head
 if wface==2 then wface+=walk end
 sspr(48,64+wface*5,8,5,0,-5-dy,8,5,wflp)
 if wface>=2 then wface=2 end

 camera()

end


function mke(fr,x,y)
 e={fr=fr,x=x,y=y, depth=0, t=0,
  vx=0,vy=0,frict=0,szx=1,szy=1

 }
 add(ents,e)
 return e
end

function upe(e)
 e.x+=e.vx
 e.y+=e.vy

 e.t+=1
 if e.upd then e.upd(e) end
 if e.life then
  e.life-=1
  if e.life<=0 then kl(e) end
 end

 -- counters
 for v,n in pairs(e) do
  if sub(v,1,1)=="c" then
   n-=1
   e[v]= n>0 and n or nil
  end
 end

 --tween
 if e.twc then
  local c=min(e.twc+1/e.tws,1)
  e.x=e.sx+(e.ex-e.sx)*c
  e.y=e.sy+(e.ey-e.sy)*c
  if e.jump then
   --local cc=sqrt(c)
   e.y+=sin(c/2)*e.jump
  end

  e.twc=c
  if c==1 then
   e.twc=nil
   e.jump=nil
   f=e.twf
   if f then
    e.twf=nil
    f()
   end
  end
 end

end

function moveto(e,tx,ty,n,f)
 e.sx=e.x
 e.sy=e.y
 e.ex=tx
 e.ey=ty
 e.twc=0
 e.tws=n
 e.twf=f
end

function dre(e)

 npal=false
	if e.depth!=depth then return end
 if e==act and t%6<=1 and not freeze then
  cl=7
  if e.price and e.price>gold then
   cl=8
  end
  apal(cl)
  npal=true
 end

 if e.cbl then
  apal(7)
  npal=true
 end

 if e.spoiled then
  pal(3,4)
  pal(11,9)
  npal=true
 end


 if e.fr> 0 and (not e.cblk or t%4<2 )then
  -- auto_anim
  if fget(e.fr,3) and e.t%4==0 then
   e.fr+=1
   if fget(e.fr,0) then
    kl(e)
    return
   end
  end
  local fr=e.fr
  local x=e.x
  local y=e.y
  if e.float then
   y += flr(sin(t/20+x/7)+.5)
  end
  if e.fly then
   fr=57+flr(cos(t/10)+.5)
  end

  spr(fr,x,y,e.szx,e.szy)
 end

 if e.dr then e.dr(e) end
 if npal then pal() end

end


function rspr(fr,x,y,rot)
	for gx=0,7 do for gy=0,7 do
  px=(fr%16)*8
  py=flr(fr/16)*8
  p=sget(px+gx,py+gy)
  if p>0 then
   dx=gx
   dy=gy
   for i=1,rot do
    dx,dy=7-dy,dx
   end
   pset(x+dx,y+dy,p)
  end
 end end
end

function dr_shelves()

 -- slots
 n=2
 for sh in all(shelves) do
 	map(0,16,n*40+5,0,5,5)
 	for i=0,8 do
 	 id=sh[i+1]
 	 if id then
 	  x,y=get_shelf_pos(n,i)
 	  clip(x,y-8,x,y)
 	  spr(id,x+6,y-9)
 	  clip()
 	 end
 	end
 	n+=1
 end

 --sides
 n=2
 for sh in all(shelves) do
  bx=n*40+15
  for i=0,1 do
   x=(bx+i*25)+5
 	 rectfill(x,0,x+2,40,12)
		end
		rectfill(bx+5,0,bx+32,8,13)
		n+=1
 end

end

--------particles library---------
function rain_particles()
	add(rain,{
		x=rnd(100),
		y=1,
		dx=-3,
		dy=4,
		life=5,
		dr=function(self)
			pset(self.x,self.y,12)
		end,
		upd=function(self)
			self.x+=self.dx
			self.y+=self.dy
			self.life-=1
			if self.life<0 then del(rain,self) end
		end
})
end
--------particles library---------


function _update()
 logp={}
 t=t+1
 ysort(ents)
 foreach(ents,upe)
 for r in all(rain) do r:upd() end
end

function _draw()
 cls()

 if ens then
  ens()
  return
 end

 map(0,0)
 if scn==0 then
	rain_particles()
	rain_particles()
	sfx(33)

  dr_shelves()
	print("midnight",40,5,12)
	print("LAUNDERETTE",50,10,12)
	print("open",6,10,8)
	--rectfill(100,31,100,0,6)
	rectfill(3,20,5,24,6)
	rectfill(39,3,71,3,8) --top red line
	rectfill(49,16,93,16,8)--bottom red line
	line(0,0,99,0,6)
	line(0,31,0,0,6)
	line(27,31,27,0,6)
	rectfill(40,42,86,52,14)
	rectfill(40,49,86,49,7)
	line(7,106,17,116,6) ----ironing board leg
	line(17,106,7,116,6) ----ironing board leg
	rectfill(1,100,20,106,11) --ironing board
	circ(114,16,4,7) --spiderweb
	circ(114,16,7,7) --spiderweb
	line(114,16,127,10,7) --spiderweb
	line(114,16,100,10,7) --spiderweb
	line(114,16,100,15,7) --spiderweb
	line(114,16,127,15,7) --spiderweb
	line(114,16,100,20,7) --spiderweb
	line(114,16,127,20,7) --spiderweb

	for r in all(rain) do r:dr() end



 end


 -- ents
 dr_ents(0)
 dr_ents(1)
 dr_ents(2)


 -- logs
 color(7)
 cursor(0,0)
 for str in all(logs) do
  print(str)
 end
 for p in all(logp) do
  pset(p.x,p.y,t%15)
 end

end

function dr_ents(dp)

 depth=dp
 for e in all(ents) do

  if e.lpy then
   clip(e.x-1,e.y-1,e.x+10,e.lpy)
  end

  if e.brd and not fading then
   --dre(e)
   border(dre,e)
  else
   dre(e)
  end

  clip()
 end


end

function log(n)
 add(logs,n)
 if #logs>16 then
  del(logs,logs[1])
 end
end

function log_pt(x,y)
 add(logp,{x=x,y=y})
end

function drop_shadow(dr)
 apal(1)
 camera(-1,-1)
 dr()
 camera()
 pal()
 dr()
end

function apal(n)
 for i=0,15 do pal(i,n) end
end

function shd(n,k)
 local x = (n%4)+(k%2)*4
 local y = n/4+flr(k/2)*4
 return sget(x,y)
end

function ysort(a)
 for i=1,#a do
  local j = i
  while j > 1 and a[j-1].y > a[j].y do
   a[j],a[j-1] = a[j-1],a[j]
   j = j - 1
  end
 end
end


function talk(text,cur,xmax,lim)

 local x=0
 local y=-tdy

 if cur<#text and t%5==0 then
  bs=9
  if port==172 then bs=11 end
	if port==142 then bs=2 end
	if port==204 then bs=4 end
	if port==140 then bs=9 end
	if port==236 then bs=16 end
  sfx(bs+rand(2))
 end

	 for i=1,cur do

  ch=sub(text,i,i)
  if ch==" " then
   vx=x
   for k=i+1,#text do
    vx+=5
    if sub(text,k,k)==" " then
     break
    end
   end
   if vx>xmax then
    x=0
    y+=6
   else
    print(ch,x,y,7)
    x+=4
   end
  else
   print(ch,x,y,7)
   x+=4
  end
 end
 if y>lim then
  tdy+=0.6
 end
end

function mk_anim(sx,sy,sz,le)
 local e=mke(0,x,y)
 local fr=0
 e.dr=function(e)
  fr=flr(e.t/4)
  if fr==le then
   kl(e)
  else
   sspr(sx,sy+fr*sz,sz,sz,e.x-sz/2,e.y-sz/2)
  end
 end
 return e
end




__gfx__
000000000000b00000dddd00000ee00000000000000000000008888000000000000000000003300000777a000ff77ff00000700000000000f9fff00000000000
00000000000b0b000d0000d0009999000000000000990000008888000000000000000000003003000aa777a0fff7ffff00e77f0000ff0000ff9bbb0000000000
00000000000b0000d000000d00a99a0000ccccc099009000007770800f0f0f000000000003000030aaaa77aa6ffffff60eeeeff000fff0000bb3bb0000000000
000000000000b000dddddddd0aaaaa000ccccc1c9900090000eee00000fffff009ebc00039999993aa97a77a677ff7766eeefff700ffff000bb73bb00000bb00
00000000000b0b00d0d00d0d0a777700cc1111cc999900900eeeee000fff7f7006e6c00008888880999aa999ffc99cff6666777700fff000007b3bb000bb9bb0
0000000000b000b0dddddddd0a7eee00c1cccccc099999990e8a8e0000fffef0096b6000008888009aa99990f779977fe666677f00ff000007073b0000bb9bb0
000000000b00000bd0d00d0d0a777700cc1111cc000000000eaaae000fff9f9009ebc00000888800099944007777777701667750000000000777700000fb9bf0
000000000bbbbbbb0dddddd00aaaaa000ccccc10099999990e8a8e00000909000000000000888800004440007777777701115551000000000707330000ff9ff0
0000000000000800008000000200000000000000000000000ffffff000000000000f0000000f0000000f0000055511100551511155555555037030300f0f9f00
000000000088880008800080000000000000000000000000f4ffffff007777700074700000747000007470000555111011151155555542450037300000f33000
000000000888880000000000000000000000000000000000f944440007070707007c7000007c7000007c70000555111011111555555522410993300009993990
000900000889980000000000000000000000000000002000f99999000777077707c0060007c0060007c0060005550110e111155f555444419433334994433349
000990000899980000800000000000000000080000000000ffffff00007070707aabb3c0777aa9c07ee882c005500440e111155f554411119944449999444499
009a90000899980000000000000009000000000000000000ffffff00077707777aabb3c0777aa9c07ee882c00550000001111550544115550997979009999990
00aaa000008980000000a000000000000000000000000000fff99999070707076bb333c06aa999c0688222c00440000000115500441155550999799009999990
000a000000000000000000000000000000000000000000000f4444400077777006cccc0006cccc0006cccc000440000000000000511555550097970000999900
00fff9006767676000000040000000001dddddd1444444440000000000000000000000000000dddddd6600000000dddddd660000555555555555555555555555
0f90099006767dd60006642000422000d111111d4111111400000000002820000000000000dd11111111d60000dd11111111d600555111111111155555555555
f90000990067ddd700064207042240001dddddd1422222240044444400888000000000000d111111111111600d11111111111160551111111111115555555555
f99999990006dd700004266704492222d11111114244442442449994007cc0000000000061113333333311166111111111111116511010101010101511111111
f9444499000467000042066704444442d66ddd11411111140049242907cccc000000000061333333333333166111111111111116510101010101001566666666
ff999999009400000420777004444444dddddd1142222224000945497c777cc0000000006733bbbbbbbb33dd67111111111111dd550000000000005555555555
ffffff990940000042000000099999901dddd1114244442400092429c77777d0000000001677bbbbbbbbddd1167711111111ddd1555000000000055555555555
0fffff909400000020000000000000000111111040000004000099900cdddd000000000011d67776ddddd11111d67776ddddd111555555555555555555555555
0009000077000000001121d62493d1d95551111111111555000000000000000009900aa000000000000000001dddddddd1111111555555552222222244444111
00999000777000000000101d1241101455166666666665550077a000000000000990aaaa0900000000d000001dd676dddd11111155555555dddddddd44444111
09909900777700000000000101200002516555555555555507999a0000000000099aaaaa0d900000099aaa001dd777ddddd11111555555556666666644444111
99000990777000000000000000100001165555555555555507999a00000000000d9aaaa000aaa000099aaaa01dd676ddddd11111555555556666666622222111
9009009077000000000000000000000055555555555555610a999a000000000000daaa00000aaa00999aaaa00dddddddddd11110555555555555555544441115
00999000000000000000000000000000555555555555561500aaa00000000000000d00000000da00990aaa0000dddddddd111110555555555555555544441115
09909900000000000000000000000000555666666666615500000000000000000000d00000000000000aaa00000dddddd1111100555555555555555544441115
99000990000000000000000000000000555511111111155500000000000000000000000000000000000a00000000011111111000555555555555555522221115
0000000000000000000000002220222222202222bbbbbbbbbbbbbbbbffffffffbb777fbb3fffffffbbbbbbb33bbbbbbbfffffff3000000000000000000666600
0000000000000000000000002220222222202222bbbbbbbbbbbbbbbbffffffffb74444fbb3ffffffbbbbbb3ff3bbbbbbffffff3b000000000000000006111160
0000000000000000000000002220222222202222bbbb3bbbbbbbbbbbffffffffb3777f3bbb3fffffbbbbb3ffff3bbbbbfffff3bb000000000000000071111116
0000000000000000000000002220222222202222bbbb3bbbbbbbbbbbffffffffb7777ffbbbb3ffffbbbb3ffffff3bbbbffff3bbb00000000000000006711116d
0000000000000000000000002220222222202222b3bb3bb3bbbbbbbbffffffff77777fffbbb3ffffbbb3ffffffff3bbbffff3bbb0000000000000000667666dd
0000000000000000000000002220222222202222bb3b3b3bbbbbbbbbffffffff77777fffbb3fffffbb3ffffffffff3bbfffff3bb00000000000000006666dddd
0000000000000000000000002220222222202222bbbbbbbbbbbbbbbbffffffff3777fff3b3ffffffb3ffffffffffff3bffffff3b00000000000000006666dddd
0000000000000000000000000000000000000000bbbbbbbbbbbbbbbbffffffffb3ffff3b3fffffff3ffffffffffffff3fffffff300000000000000006666dddd
000000001111111100000000222222202222222099999999ffffffff3bbbbbb3ffffffff97777779333333333333b3333bb33bbbbb3bbbb3000000000666ddd0
000000001111111100000000222222202222222099999999fffffffff3bbbb3fffffffff77666677bb33b333333333bb3bb33bbbbbbbb3b3000000000066dd00
000000001111111100000000222222202222222099999999ffffffffff3bb3ffffffffff76777767b3b33333333333bb333bbbb3bbb33b330000000000666600
000000001111111100000000222222202222222044444444fffffffffff33fffffffffff76777767bb3333333b33bb33b33b33bb33b333330000000006676660
00000000dddddddd00000000222222202222222099999999fffffffffffffffffff33fff77666677bb33b33b33333b33333333bb33bb33b300000000667dd667
00000000dddddddd00000000222222202222222099999999ffffffffffffffffff3bb3ff477777743bbbb33333b33bbb33333b3bbb33333300000000d666667d
00000000dddddddd00000000222222202222222099999999fffffffffffffffff3bbbb3f94444449bbb33bb33b3bbbbb333b33bbbb333333000000000d6667d0
00000000cccccccc00000000000000000000000099999999ffffffffffffffff3bbbbbb399999999bbb33bb33bbbb3bb33333333333b33330000000000dddd00
00000000c11111110000000000000000000000004444444444444444444444442eeeee2099999999333333331111111111111111bbb77bbbbbbbbbbb00000000
00eeee00c1cccccc000000000000000000000000444444444444444444444444eeeeeee099999999333333331111111111111111bbb77bbbbb6666bb00000000
00eeee00c1cdcdcc000000000000000000000000441111111111111111111144eeeeeee099999999333333331111111111111111b776677bb6667ddb00000000
00eeee00c1cddd1c000000000000000000000000441111111111111111111144deeeeed099999999333333331111113111111111b776677b6677dddb00000000
eeeeeeeec1cc111ceeeeeeee0000000000000000333333333333333333333333ddddddd099999999333333331131133111111111bbb77bbb677dddd300000000
0eeeeee0cccccccceeeeeeee000000000000000033b3b33333333b3333333333dd111dd099999999333333331133131111111111bbb77bbb666ddd3300000000
00eeee00ddddddddeeeeeeee0000000000000000bbbbbbbbbbbbbbbbbbbbbbbbdd122dd099999999333333331113111111111111bbb3bbbbbb33333300000000
000ee000dddddddd0e0000e00000000000000000bbbbbbbbbbbbbbbbbbbbbbbb0000000099999999333333331111111111111111bbb3bbbbbbbb333300000000
00000000000000000000000088828802888088020882088088800880888288828888800013333331311111111111311113311333331333310000b00000000000
0000000000000000000000008882880288828802888288028802880288000880880080009133331933113111111111331331133333333131000b0b0000000000
0000000000000000000000008800880288028802880088028802880288000880880080009913319931311111111111331113333133311311000b000000000000
00000000000000000000000088008802880288028880880288028802880008808800800099911999331111111311331131131133113111110000b00000000000
0000000000000000000000008800888288800880088288028880880288800880888880009999999933113113111113111111113311331131000b0b0000000000
000000000000000000000000880088028802088000828802880088028800088088008000999999991333311111311333111113133311111100b000b000000000
00000000000000000000000088828802880208808882880288008802880008808800800099999999333113311313333311131133331111110b00000b00000000
00000000000000000000000088828802880208808880088088000880888288828800800099999999333113311333313311111111111311110bbbbbbb00000000
011fffff11000111ffff11000011fffff1100011ffff111001111110006666000000000000000000011111100666777011551111115555112226666777777722
0011fff11000000fcffcf0000001ffff1100000fcffcf000111ff111063bbb6000000000000000001111111166677777155111ee111111512666667777777772
000fcffcf00000f0ccccf000000fcffcf000000fcccc0f0011ffff116371bb1600666000007770001111ffdd667777775511eeeeeee111112666677777777772
000fccccf00000f0cccff000000ffcccf000000fcccc0f001f5ff5f1637bb1b60600060007777700d119111d66777777111e1eefff1e11112666677777777772
000fccccf0000000cccc00000000ccccf0000000fccc00001e5ff5e1633bb7b660000060771717709919f1ff1117711111111effff111e112611677711777772
000111111000000dd1111000000111ddd0000001111dd0000111111063337bb66000006071070170999fffff61177117111111fff11111112111177111117772
000110011000000ddd11100000011dddd000000111ddd0001d1111d106333b60600000607707077009999ff006617770117111fff11171112661177711177772
000cc00cc0000000cc0cc000000cc00cc000000cc0cc000011dddd11006666006000006077777770009fff000066777011711fffff117f112611677111777772
01111111110001111111110000111111111000111111111011111111006666006000006077707770011991100000006011eeeffffffff1152666677777771722
001111111000000f1111f000001111111100000f1111f00011111111063333606000006070777070111116610800088621eeeeffffffff152666617777717222
000f1111f00000f0ccccf000000f1111f000000fcccc0f0001111110633377366000006007070700f111166f77828877211eef222ffff1112226611777716222
000fccccf00000f0ccccf000000fccccf000000fcccc0f001d111111633bb1b66000006070070070fff116ff778288772511efe2efff11152226677777716222
000fccccf0000000cccc0000000fcccc00000000cccc000011dd1ff1637bbbb66060606077777770033333330882888621511ffffffe11112226171717176222
000111111000000dd11110000001111110000001111dd0001111f5f06bb71bb60606060007070700ff33ff3000828666211111ffffee11112222617171776772
000110011000000ddd111000000110011000000111ddd0001111e5f006bbb1600000000000000000ff00ff000700700022222222eeee2c222222777777766777
000cc00cc0000000cc0cc000000cc00cc000000cc0cc0000011111000066660000000000000000003300330070070000222222cfeeeeccff2222222222667777
000111fff00000011ffff0000001111ff0000001111ff0001d1111100066660055555555555555550050050000088000222277777ffffe222255155111551551
0000111f10000000fcff00000000cfcf00000000ccfc000011d1ff1106b3336055555555555555550005500000eeee0022272fffffffffe22577511111111151
0000cfcc0000000fccfcf0000000cfcc0000000fcccf000011ff5f116bb733365555555555555555105555010e8888e02222effffeeffffe1775111111111111
0000cfcc0000000fccccff000000ccfc0000000fccccf00011fe5f106b7bb336500c00ccccccccc55155551508eeee8022777effee777efe15111199999ddd11
00001f110000000f111100000000111f0000000011110000011111106b1bb7365555555555555555515775150e8888e0277777ffe77777fe111119911119ddd1
0000111100000000111100000000111100000000111100000d11111161bb17365ccccc6666ccccc55185581508c88c80222eec999ccee7ee129999999999dddd
000001100000000111ccc000000001100000000ccc11100011dd1ff106bbb3605cccc600006cccc55100001500866800222e9999999ffffe22111991111fdddd
00000cc00000000cc00cc00000000cc00000000cc00cc000111ff5f0006666005ccc60770006ccc505500550006006002229999999effffe227119f1171fddf9
00dddd0000dddd0000400004400000000099990000000000111fe5f0006666005ccc60700006ccc500000000000000002229999999eeeeee229999ffffffff9f
0d0000d00d8888d0044444440000000000191900bb00000001111110061bbb605ccc60000706ccc5007b300000000000227999999d6eeee62299fffffffffff9
d000000dd888999d00455544c44440000ffff990bbbbb0001d1111116bb17bb65ccc60007006ccc507bbb300000000002776999dd667766622999fffffffff22
dddddddddddddddd00155114c444444088ff0f99bbbbbbb011dd1ff06bbbb7365cccc600006cccc5bbbbbb30000110007777766666777766229999999ffff922
d0d00d0dd8d8cd9d0055544c44454540800000f9bbbbbbbb1111ff506b1bb3365ccccc6666ccccc5b1bb1b330018810077777fff7d7777662229999fffff9922
dddddddddddddddd005155c44554554000000f99bbbbbbb00111fe50637733365555555555555555bb1bbb33018118107677deeed777776622229ffffff99911
d0d00d0ddcdccd9d04585560544454400000f990bbbbb00000000000063333605cccccccccccccc53bbbb333181001816667766677676666222229fff9999111
0dddddd00dddddd04400440000000000000f9900bb00000000000000006666005cccccccccccccc5033333308100001866677777766666662222222229991111
00ffffffffffffff00ccccccc00000000000000000000000000cccccccccc0000000700000000000224442222244442222115222222251122222222222222222
0f94ffffffffffff0cc4444cccccc000000000000000000000c0000000000c0000e77f0005555500244442222244444222115522222551122222444444222222
f9994fffffffffff0c455544ccccccc000000000000000000c000000000000c00eeeeff056555550245544444444554222511552225511522294999999942222
f9994fffffffffff0c155114cccccccc00000000000000000c000000000000c06eeefff756665555445544444444554422151552225515122249944444994222
f9994444444444440c55544c1ccccccc00000000000000000c000000000000c066667777eef0f55044244f555f44424422151155555115122994499171499422
f9999999999999990c5155ccc1cccccc00000000000000000c000000000000c0e666677f0ffff500222411555114422222515155e5515152944ff44171944922
f99fffffffffffff045855cccc11cccc00000000000000000c000000000000c0016677505055555022211156511142222255555eee555552499ffff999999992
f9ffffffffffffff44c44ccccccc111100000000000000000c000000000000c001115551005555002227115651174222255588e1e1e8855544ffffffff494f42
9fffffffffffffff000000000000000000000000000000000c000000000000c005515111000000002224556555544222255555eeeee55555444ff222fffffff2
9fffffffffffffff000000000000000000000000000000000c000000000000c01115115500000000222555555555422225555ee717ee555594ff222222fff8f2
9fffffffffffffff000000000000000000000000000000000c000000000000c011111555000000002255511155555222215557111117555199fff22222222822
9fffffffffffffff000000000000000000000000000000000c000000000000c0e111155f0000000022515111515552222511575111575115299fff2222228882
9ffff99999999999000000000000000000000000000000000c000000000000c0e111155100000000225555155555c422555511555551155524499ff222228282
9ffff99999999999000000000000000000000000000000000c000000000000c00111155100000000225551515555c4225555551111155555224499ff22282228
09ff944444444444000000000000000000000000000000000c000000000000c00111555100000000222552cc555cc4421155555555555511222994ff22222222
0099444444444444000000000000000000000000000000000c000000000000c0001155010000000022222266cccc444411155555555551112222944ff2222222
000000000000000000000000000000000c000000000000c00c000000000000c00c000000000000c02222777777722222222bbb33333332228822222222222288
000000000000000000000000000000000cccccccccccccc00cccccccccccccc00cccccccccccccc0222777777777222222b777b3333333228882888888882888
000000000000000000000000000000000c666666666666c00c666666666666c00c666666666666c022777777777772222bb777bbb333333228888eeeeee88882
00000000000000000011111100000000cc060060060060cccc060060060060cccc060060060060cc2277117771177222b77bbbbbbbb33332228eee8888eee822
00000000000000000115ff51100000006c666666666666c66c660033330066c66c660033330066c62771117771117722b77bbbbbbbbb333328ee88888888ee82
000000000000000001f5ff5f1000000060cccccccccccc0660cccccccccccc0660cccccccccccc062771177777117722b7711bbb11bbb3338e888988889888e8
0000000000000000f1ff22ff1f0000006606006006006066660603600630606666060360063060662711117771111722bb111bbb111bbb338888889889888888
0000000000000000f1ef2efe1f00000006c6666666666c6006c6666666666c6006c6666666666c602777117771177722bbb11bbbb11bbb33287c888888887c82
0000000000000000f1fffff11f0000000606060606060060060608688680606006060868868060602777777777777722bb111bbb111bbb3328cc88888888cc82
00000000000000000f1fff11f0000000066c66666666c660066c66666666c660066c66666666c6602777777177777722bbbbbbbbbbbbbb33988877c8877c8889
000000000000000000fcf11f000000000060060606060600006000888800060000600088880006002777777177777722bbbbbb11bbbbbb338898ccc88ccc8988
0000000000000000000cccc0000000000066ccccccccc6000066ccccccccc6000066ccccccccc6002777777777777722bbbbbb11bbbbbb338818ccc66ccc8188
0000000000000000000cccc0000000000060000000000600006000000000060000600000000006002777777777777722bbbbbbbbbbbbb3338121866666681218
0000000000000000000111100000000000666666666666000066666666666600006666666666660027771777771777223bbbbbbbbbbb33338122166ee6612218
00000000000000000011001100000000065600000000656006560000000065600656000000006560227177777771722233bbbbbbbb3333328122266116622218
00000000000000000cc0000cc0000000065600000000656006560000000065600656000000006560221777777777122233333333333333228122211221122218
__label__
6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666dddddddddddddddddddddddddddd
60000000c00000000000000000060000000000000000000000000c0000000000000000000000000000000000000000000000dddddddddddddddddddddddddddd
6000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddd
6000000000000000000000000006000000000008888888888888888888888888888888880000000000000000000000000000dddddddddddddddddddddddddddd
6000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddd
6000000000000000000000000c06000000000000ccc0ccc0cc00cc00ccc00cc0c0c0ccc00000000000000000000c00000000dddddddddddddddddddddddddddd
6000000000000000000000000006000000000000ccc00c00c0c0c0c00c00c000c0c00c000000000000000000000000000000dddddddddddddddddddddddddddd
6000000000000000000000000006000000000000c0c00c00c0c0c0c00c00c000ccc00c000000000000000000000000000000dddddddddddddddddddddddddddd
6000000000000000000000000006000000000000c0c00c00c0c0c0c00c00c0c0c0c00c000000000000000000000000000000dddddddddddddddddddddddddddd
6000000000000000000000000006000000000000c0c0ccc0ccc0c0c0ccc0ccc0c0c00c00000000000c00c000000000000000ccc11b1111d177777d11a99a1ccc
600000088088808880880000000600000000000000000000000000000000000000000000000000000000000000000000000077c111b11177ddddd77aaaaa1c77
60000080808080800080800000060000000011000111111000c000ccc0c0c0cc00cc00ccc0ccc0ccc0ccc0ccc0ccc0000000cc771b1117d1d11d1d11177777cc
600000808088808800808000000600000011bb101666777100c000c0c0c0c0c0c0c0c0cc00c0c0cc000c000c00cc00000000cccd771881ddd777dd188177dccc
6000008080800080008080000006000001bb9bb16667777710c000ccc0c0c0c0c0c0c0c000cc00c0c00c000c00c000000000cccbd1811817711d71811817dccc
6000008800800088808080000006000001bb9bb16677777710ccc0c0c00cc0c0c0cc00ccc0c0c0ccc00c000c00ccc0000000cccb1817118118811811a181dccc
6000000000000000000000000006000001fb9bf1667777771000000000000000000000000000000000000000000000000000777781718811eeee118817187777
600000000000b000000000000006000001ff9ff1111771111888888888888888888888888888888888888888888888000000ccc11118111e8888e11181881ccc
60000000000b0b0000000000000600001f1f9f1161177117100011110000000000000000c00000000c000000000000000000ccc1c1811818eeee818118118ccc
60000000000b0000000000000006000001f33110166177710001888810000000000000000000000000000000000000000000ccccc811811e8888e11811811ccc
600000000000b000000000000006000019993991016677710018888100000000000000000000000000000000000000000000cc7777181c18c88c811181e777cc
60066600000b0b0000000000000600019443334911111161001777181000000000000000000000000000000000000000000077c1cc817cd1866819de188edc77
6006660111b000b000000000000600019944449918111886101eee110c000000000000000000000000000000000000000000cccc1111c7d161161dd7aaaedccc
600666177710000b0000000000060000199999917782887711eeeee100000000000000000000000000000000000000000000cccccccc1d771991977e8a8edccc
600661777771bbbb0000000000060000199999917782887711e8a8e100000000000000000000000000000000000000000000cccccccccccc77777ccccccccccc
60061771717710000000000000060000519999151882888611eaaae155555555555555555555555555555555555555550000ccc1111111111111111131131ccc
60001711711710011111000000060000551111555182866611e8a8e155555555555555555555555555555555555555550000cccf1f1f11111111111311113ccc
600017717177101ccccc10000006000055555555171171115511111555555555555555555555555555555555555555550000ccc1fffff119ebc1113999999ccc
60001777777711ccccc1c10000060000500c00c171171cc5500c00ccccccccc5500c00ccccccccc5500c00ccccccccc50000cccfff7f7116e6c1111888888ccc
6000177717771cc1111cc1000006000055555555155155555555555555555555555555555555555555555555555555550000cccdfffefdd96b6ddddd8888dccc
6000171777171c1cccccc100000600005ccccc6666ccccc55ccccc6666ccccc55ccccc6666ccccc55ccccc6666ccccc50000cccfff9f9dd9ebcddddd8888dccc
6000017171711cc1111cc100000600005cccc600006cccc55cccc600006cccc55cccc600006cccc55cccc600006cccc50000cccdd9d9dddddddddddd8888dccc
60001711711711ccccc11000000600005ccc60770006ccc55ccc60770006ccc55ccc60770006ccc55ccc60770006ccc50000cccccccccccccccccccccccccccc
222017777777121111112222222022225ccc60700006ccc55ccc60700006ccc55ccc60700006ccc55ccc60700006ccc52220ccc111111c1111111c1111111ccc
222021717171222222202222222022225ccc60000706ccc55ccc60000706ccc55ccc60000706ccc55ccc60000706ccc52220cccccccccc1ccccccc1ccccccccc
222022121210222222202222222022225ccc60007006ccc55ccc60007006ccc55ccc60007006ccc55ccc60007006ccc52220ccccdcdccc1cdcdccc1cdcdccccc
222022222220222222202222222022225cccc600006cccc55cccc600006cccc55cccc600006cccc111111600006cccc52220ccccddd1cc1cddd1cc1cddd1cccc
222022222220222222202222222022225ccccc6666ccccc55ccccc6666ccccc55ccccc6666cccc111111116666ccccc52220ccccc111cc1cc111cc1cc111cccc
2220222222202222222022222220222255555555555555555555555555555555555555555555511111111115555555552220cccccccccccccccccccccccccccc
222022222220222222202222222022225cccccccccccccc55cccccccccccccc55cccccccccccc11111ffdd1cccccccc52220cccddddddddddddddddddddddccc
000000000000000000000000000000005cccccccccccccc55cccccccccccccc55cccccccccccc1d119111d1cccccccc50000cccddddddddddddddddddddddccc
2222222022222220222222202222222022222220222222202222222022222220222222202222219919f1ff10222222202222ccc0222222202222222022222ccc
222222202222222022222220222222202222222022222220222222202222222022222220222221999fffff102222222022222220222222202222222022222220
2222222022222220222222202222222022222220eeeeeeeeeeeeeeeeeeeeee1eeee11eeeeeeeee19999ff1e02222222022222220222222202222222022222220
2222222022222220222222202222222022222220eeeeeeeeeeeeeeeeeeeee141111441eeeeeeeee19fff1ee02222222022222220222222202222222022222220
2222222022222220222222202222222022222220eeeeeeeeeeeeeeeeeeee1444444411111eeeee11199111e02211112022222220222222202222222022222220
2222222022222220222222202222222022222220eeeeeeeeeeeeeeeeeeeee1455544c444411ee1111116611021dddd1022222220222222202222222022222220
2222222022222220222222202222222022222220eeeeeeeeeeeeeeeeeeeee1155114c4444441e1f111166f101d8888d122222220222222202222222022222220
0000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeee155544c44454541e1fff116ff11d888999d10000000000000000000000000000000
2220222222202222222022222220222222202222eeeeeeeeeeeeeeeeeeeee15155c445545541ee1333333311dddddddd12202222222022222220222222202222
222022222220222222202222222022222220222277777777777777777777145855615444544171ff33ff3171d8d8cd9d12202222222022222220222222202222
2220222222202222222022222220222222202222eeeeeeeeeeeeeeeeeee14411441e1111111ee1ff11ff1ee1dddddddd12202222222022222220222222202222
2220222222202222222022222220222222202222eeeeeeeeeeeeeeeeeeee11ee11eeeeeeeeeee13311331ee1dcdccd9d12202222222022222220222222202222
2220222222202222222022222220222222202222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee11ee11eee21dddddd122202222222022222220222222202222
22202222222022222220222222202222222022222220222222202222222022222220222222202222222022222111111222202222222022222220222222202222
22202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222
00000000000000000000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000000000000000000000
222222202222222022222220222222202222222022222220222222202222111ff111222022222220222222202222222022222220222222202222222022222220
22222220222222202222222022222220222222202222222022222220222211ffff11222022222220222222202222222022222220222222202222222022222220
2222222022222220222222202222222022222220222222202222222022221f5ff5f1222022222220222222202222222022222220222222202222222022222220
2222222022222220222222202222222022222220222222202222222022221e5ff5e1222022222220222222202222222022222220222222202222222022222220
2222222022222220222222202222222022222220222222202222222022211fffff11222022222220222222202222222022222220222222202222222022222220
22222220222222202222222022222220222222202222222022222220222211fff112222022222220222222202222222022222220222222202222222022222220
2222222022222220222222202222222022222220222222202222222022222fcffcf2222022222220222222202222222022222220222222202222222022222220
0000000000000000000000000000000000000000000000000000000000000fccccf0000000000000000000000000000000000000000000000000000000000000
2220222222202222222022222220222222202222222022222220222222202fccccf0222222202222222022222220222222202222222022222220222222202222
22202222222022222220222222202222222022222220222221102222222021111110222222202222222022222220222222202222222022222220222222202222
2220222222202222222022222220222222202222222022221ee12222222021122110222222202222222022222220222222202222222022222220222222202222
2220222222202222222022222220222222202222222022219999122222202cc22cc0222222202222222022222220222222202222222022222220222222202222
222022222220222222202222222022222220222222202221a99a1222222022222220222222202222222022222220222222202222222022222220222222202222
22202222222022222220222222202222222022222220221aaaaa1222222022222220222222202222222022222220222222202222222022222220222222202222
22202222222022222220222222202222222022222220221a77771222222022222220222222202222222022222220222222202222222022222220222222202222
00000000000000000000000000000000000000000000001a7eee1000000000000000000000000000000000000000000000000000000000000000000000000000
22222220222222202222222022222220555555555555551a77771555555555555555555555555555555555555555555522222220222222202222222022222220
22222220222222202222222022222220555555555555551aaaaa1555555555555555555555555555555555555555555522222220222222202222222022222220
22222220222222202222222022222220555555555555555111115555555555555555555555555555555555555555555522222220222222202222222022222220
22222220222222202222222022222220500c00ccccccccc5500c00ccccccccc5500c00ccccccccc5500c00ccccccccc522222220222222202222222022222220
22222220222222202222222022222220555555555555555555555555555555555555555555555555555555555555555522222220222222202222222022222220
222222202222222022222220222222205ccccc6666ccccc55ccccc6666ccccc55ccccc6666ccccc55ccccc6666ccccc522222220222222202222222022222220
222222202222222022222220222222205cccc600006cccc55cccc633336cccc55cccc600006cccc55cccc600006cccc522222220222222202222222022222220
000000000000000000000000000000005ccc60770006ccc55ccc63337736ccc55ccc60770006ccc55ccc60770006ccc500000000000000000000000000000000
222022222220222222202222222022225ccc60700006ccc55ccc633bb1b6ccc55ccc60700006ccc55ccc60700006ccc522202222222022222220222222202222
222022222220222222202222222022225ccc60000706ccc55ccc637bbbb6ccc55ccc60000706ccc55ccc60000706ccc522202222222022222220222222202222
222022222220222222202222222022225ccc60007006ccc55ccc6bb71bb6ccc55ccc60007006ccc55ccc60007006ccc522202222222022222220222222202222
222022222220222222202222222022225cccc600006cccc55cccc6bbb16cccc55cccc600006cccc55cccc600006cccc522202222222022222220222222202222
222022222220222222202222222022225ccccc6666ccccc55ccccc6666ccccc55ccccc6666ccccc55ccccc6666ccccc522202222222022222220222222202222
22202222222022222220222222202222555555555555555555555555555555555555555555555555555555555555555522202222222022222220222222202222
222022222220222222202222222022225cccccccccccccc55cccccccccccccc55cccccccccccccc55cccccccccccccc522202222222022222220222222202222
000000000000000000000000000000005cccccccccccccc55cccccccccccccc55cccccccccccccc55cccccccccccccc500000000000000000000000000000000
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222211111111112022222220
222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202221ccc1cc1ccc1022222220
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220221c1115115111c122222220
2222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222021c121215512121c12222220
2222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222021c111155551111c12222220
2222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222021c115155551511c12222220
0000000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c115157751511c10000000
2220222222211991222022222220222222202222222022222220222222202222222022222220222222202222222022222220222221c115185581511c12202222
2220222222199119122022222220222222202222222022222220222222202222222022222220222222202222222022222220222221c115111111511c12202222
2220222222199111912022222220222222201222222022222220222222202222222022222220222222202222222022222220222221c121551155121c12202222
2220222222199991191022222220222222117122222022222220222222202222222022222220222222111122222022222220222221c122112211221c12202222
2bbbbbbbbbb199999991bb222220222221e77f12222022222220222222202222222022222220222221999912222022222220222221c122222220221c12202222
2bbbbbbbbbbb1111111bbbbbb22022221eeeeff1222022222220222222202222222022222220222221191912222022222220222221c122222220221c12202222
2bbbbbbbbbb199999991bbbbbbb022216eeefff712202222222022222220222222202222222022221ffff991222022222220222221c122222220221c12202222
0bbbbbbbbbbb1111111bbbbbbbbb000166667777100000000000000000000000000000000000000188ff1f99100000000000000001c100000000001c10000000
2bbbbbbbbbbbbbbbbbbbbbbbbbb22221e666677f1222222022222220222222202222222022222221811121f9122222202222222021c122202222221c12222220
2bbbbbbbbbbbbbbbbbbbbbbbb222222011667751222222202222222022222220221111202222222012111199122222202222222021c122202222221c12222220
2bbbbbbbbbbbbbbbbbbbbb20222222201111555112222220222222202222222021dddd102222222021dddd11222222202222222021c111111111111c12222220
22222220622222206222222022222220155151111222222022222220222222201d1111d1222222201d8888d1222222202222222021cccccccccccccc12222220
2222222026222226222222202222222111151155122222202222222022222221d111111d12222221d888999d122222202222222021c666666666666c12222220
2222222022622260222222202222222111111555122222202222222022222221dddddddd12222221dddddddd12222220222222201cc161161161161cc1222220
22222220222626202222222022222221e111155f122222202222222022222221d1d11d1d12222221d8d8cd9d122222202222222016c661133331166c61222220
00000000000060000000000000000001e111155f100000000000000000000001dddddddd10000001dddddddd1000000000000000161cccccccccccc161000000
2220222222262622222022222220222211111551222022222eeeee2022202221d1d11d1d12202221dcdccd9d1220222222202222166161361163161661202222
22202222226022622220222222202222e111551022202222eeeeeee0222022221dddddd1222022221dddddd12220222222202222216c6666666666c612202222
22202222262022262220222222202222ee1111e022202222eeeeeee022202222e111111022202222e11111102220222222202222216161868868161612202222
22202222622022226220222222202222deeeeed022202222deeeeed022202222deeeeed022202222deeeeed022202222222022222166c66666666c6612202222
22202226222022222620222222202222ddddddd022202222ddddddd022202222ddddddd022202222ddddddd02220222222202222221611188881116122202222
22202222222022222220222222202222dd111dd022202222dd111dd022202222dd111dd022202222dd111dd0222022222220222222166ccccccccc6122202222
22202222222022222220222222202222dd122dd022202222dd122dd022202222dd122dd022202222dd122dd02220222222202222221611111111116122202222
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001666666666666100000000
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220216561111111165612222220
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220216561202222165612222220
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220221112202222211122222220
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0100000000000000000000000000000008080808080801000000000000020000000000000101010000000000000202020000000002020000000000000002020000000000000808000100000000000000000100000001000000010808080800000001000000000000000008080808010000000000000000000000080808080000
0000000000000000000000000000000000000000000000000000000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000000000000000000000000017006c7b6a5b454545454545455a6a7a6c6c454545464546464646464645464545453000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000007b6a5b454545454545466d45455a6a7a454545464646464545464646454546450286030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007e00000000000000000000000000006a5b456d454545454545454545456a6a454646464545454545465555555555450401860603000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000a8a9a8a9a8a9a8a9000000005b454646464546454645454545455a6a454646464646464648466566666667450586040403000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43444344b8b9b8b9b8b9b8b94344434457574b6a6a5c4545454545454645455a46595559555955594645454a574b45450403038609000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
535453545354535453545354535453545656567979794b464545454545454545486566666666666746464649564c45450686070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
434443444344434443444344434443445647566969694c45454645454545454557574b4a575757574b4a5756565657570202028608000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5354535453545354535453545354535458585858585858454646454546454545565656475656565656565656565647560501860708000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4344434443444344434443444344434445454545454545464645454545456a5c565647475656565656564756696969690802860900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
53545354a8a9a8a9a8a9a8a9535453544545454645454546464545456d5d6a6a56565656565656565656565669696969090807860a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43444344b8b9b8b9b8b9b8b9434443445c454545454545454545455d6a6a6a7d585858585858585858585858585858580101860500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
535453545354535453545354535453546a456d45454546454545455a6a6a7d6c464646464646464646464646464646460201018606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
434443444344434443444344434443447c5c45454545454545454545455a6a7a455559555955595559554646464546460305860701010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
535453545354535453545354535453547b6a5c454545454545454545455d6a7d466566666666666666674646464646460701860605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
434443446844684468446844434443447d7c6a6a5c454545454645455d6a7d6c464668466846684668454646466e46450403018608000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
535453545354535453545354535453546c6c7c6a6a5c45454545455d6a7d6c6c46464646464646464646466e464646460604038609000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70405151518c8dc0c1c1c1c200cccdcdcdcd0000000000000000000000000000000000000000000000000000000000000101860203040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40505151519c9d5656565600fddcdddddddd00010d020d030d040d050d060d070d080d090000000000000000000000000202040486090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505051515100005656565600fdecedededed0000000000000000000000000000000000000000000000000000000000003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5050515151000056565656000000fc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71726161610000d0d1d1d1d20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2021222324252627000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0605040308060803000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010500003461400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011500003054030520305100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002b0542b055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000745507435000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001f62500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001362500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600001f61400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001361400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000184501f352241222d11500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001f05500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002105500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001155500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f3501f310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000376542b6341f6241361400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002d5552d515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c5550c515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f0422b5212b5150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000735507315000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800002105500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f65407621070350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001335515442183250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800001f3541f2251f1150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001f055131151d055291151d315131151a0551a1121b0551a05518055181121d025110151a0251101518052180421803218022180121801218012180150000000000000000000000000000000000000000
012000001f3251f3451f3751f3551f3351f3251f31500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f3551b355183551d3351d3251d3150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000018055180051f0550000524055000051332300005220551f005111151f0551d005111151d055000051b0551b0051b0551b0521b0550000513333000051d05500005111151805500005111151605500000
01100000115341d511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001d53411511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010900003705037030370100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000c6100c6100c6100e6100c6100c61010610106100c6100c6100c610116101161011610116100c6100c6100c6100e6100e6100e610106100c6100c61011610116100c6100c6100e610106100c6100c610
011000000d617146171b617216171e61719617106170b617086170361204612086120d61704612086120d617146171b617216171e61719617106170b617086170361204612086120d6170461208612216001e600
__music__
00 01020304

