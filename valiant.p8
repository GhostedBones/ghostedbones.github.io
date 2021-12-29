pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- gh0st + daniel linssen + matt thorson + noel berry

-- globals --
-------------

room = { x=0, y=0 }
objects = {}
types = {}
freeze=0
shake=0
will_restart=false
delay_restart=0
got_fruit={}
has_dashed=false
sfx_timer=0
has_key=false
pause_player=false
flash_bg=false
music_timer=0

buttons=0
chest=0

k_left=0
k_right=1
k_up=2
k_down=3
k_jump=4
k_dash=5

-- entry point --
-----------------

function _init()
	cls()
	title_screen()
end

function title_screen()
	got_fruit = {}
	for i=0,29 do
		add(got_fruit,false) end
	frames=0
	deaths=0
	max_djump=1
	start_game=false
	start_game_flash=0
	music(40,0,7)

	load_room(7,3)
end

function begin_game()
	frames=0
	seconds=0
	minutes=0
	music_timer=0
	start_game=false
	music(0,0,7)
	load_room(0,0)
end

function level_index()
	return room.x%8+room.y*8
end

function is_title()
	return level_index()==31
end

-- effects --
-------------

clouds = {}
for i=0,8 do
	add(clouds,{
		x=rnd(64),
		y=rnd(64),
		spd=1+rnd(1.5),
		w=32+rnd(16)
	})
end

particles = {}
for i=0,24 do
	add(particles,{
		x=rnd(128),
		y=rnd(128),
		s=0+flr(rnd(5)/4),
		spd=0.25+rnd(5),
		off=rnd(1),
	 c=11+flr(rnd(3))
	})
end

dead_particles = {}



-- player entity --
-------------------

player =
{
	init=function(this)
		this.p_jump=false
		this.p_dash=false
		this.grace=0
		this.jbuffer=0
		this.djump=max_djump
		this.dash_time=0
		this.dash_effect_time=0
		this.dash_target={x=0,y=0}
		this.dash_accel={x=0,y=0}
		this.hitbox = {x=1,y=3,w=6,h=5}
		this.spr_off=0
		this.was_on_ground=false
		--create_hair(this)

	end,
	update=function(this)
		if (pause_player) return

		local input = btn(k_right) and 1 or (btn(k_left) and -1 or 0)

		-- spikes collide
		if spikes_at(this.x+this.hitbox.x,this.y+this.hitbox.y,this.hitbox.w,this.hitbox.h,this.spd.x,this.spd.y) then
		 kill_player(this) end

		-- lava collide
		if lava_at(this.x+this.hitbox.x,this.y+this.hitbox.y,this.hitbox.w,this.hitbox.h,this.spd.x,this.spd.y) then
		 kill_player(this) end

		-- mob collide
--		if mob_at(this.x+this.hitbox.x,this.y+this.hitbox.y,this.hitbox.w,this.hitbox.h,this.spd.x,this.spd.y) then
-- 		kill_player(this) end

		-- bottom death
		if this.y>128 then
			kill_player(this) end

		local on_ground=this.is_solid(0,1)
		local on_ice=this.is_ice(0,1)

		if this.spd.y < 0 then on_ground=false end

		-- smoke particles
		if on_ground and not this.was_on_ground then
		 init_object(smoke,this.x,this.y+4)
		end

		local jump = btn(k_jump) and not this.p_jump
		this.p_jump = btn(k_jump)
		if (jump) then
			this.jbuffer=4
		elseif this.jbuffer>0 then
		 this.jbuffer-=1
		end

		local dash = btn(k_dash) and not this.p_dash
		this.p_dash = btn(k_dash)

		if on_ground then
			this.grace=6
			if this.djump<max_djump and this.dash_time <= 0 then
			 if this.dash_effect_time<=0 then psfx(54) end
			 this.djump=max_djump
			end
		elseif this.grace > 0 then
		 this.grace-=1
		end

		this.dash_effect_time -=1
  	if this.dash_time > 0 then
   		init_object(smoke,this.x,this.y)
  		this.dash_time-=1
  		this.spd.x=appr(this.spd.x,this.dash_target.x,this.dash_accel.x)
  		this.spd.y=appr(this.spd.y,this.dash_target.y,this.dash_accel.y)
  	else

		-- move
		local maxrun=1
		local accel=0.6
		local deccel=0.15

		if not on_ground then
			accel=0.4
		elseif on_ice then
			accel=0.05
		end

		if abs(this.spd.x) > maxrun then
	 	this.spd.x=appr(this.spd.x,sign(this.spd.x)*maxrun,deccel)
		else
			this.spd.x=appr(this.spd.x,input*maxrun,accel)
		end

		--facing
		if this.spd.x!=0 then
			this.flip.x=(this.spd.x<0)
		end

		-- gravity
		local maxfall=2
		local gravity=0.21

  	if abs(this.spd.y) <= 0.15 then
   		gravity*=0.5
	end

	-- wall slide
	if input!=0 and this.is_solid(input,0) and not this.is_ice(input,0) then
	 	maxfall=0.4
	 	if rnd(10)<2 then
	 		init_object(smoke,this.x+input*6,this.y)
			end
		end

		if not on_ground then
			this.spd.y=appr(this.spd.y,maxfall,gravity)
		end

		-- jump
		if this.jbuffer>0 then
		 	if this.grace>0 then
		  	-- normal jump
		  	psfx(1)
		  	this.jbuffer=0
		  	this.grace=0
					this.spd.y=-2
					init_object(smoke,this.x,this.y+4)
				else
					-- wall jump
					local wall_dir=(this.is_solid(-3,0) and -1 or this.is_solid(3,0) and 1 or 0)
					if wall_dir!=0 then
			 		psfx(2)
			 		this.jbuffer=0
			 		this.spd.y=-2
			 		this.spd.x=-wall_dir*(maxrun+1)
			 		if not this.is_ice(wall_dir*3,0) then
		 				init_object(smoke,this.x+wall_dir*6,this.y)
						end
					end
				end
			end

		-- dash

		local d_full=5
		local d_half=d_full*0.70710678118

		if this.djump>0 and dash then
		 	init_object(smoke,this.x,this.y)
		 	this.djump-=1
		 	this.dash_time=4
		 	has_dashed=true
		 	this.dash_effect_time=10
		 	local v_input=(btn(k_up) and -1 or (btn(k_down) and 1 or 0))
		 	if input!=0 then
			  	if v_input!=0 then
				   	this.spd.x=input*d_half
				   	this.spd.y=v_input*d_half
			  	else
				   	this.spd.x=input*d_full
				   	this.spd.y=0
			  	end
			elseif v_input!=0 then
			 		this.spd.x=0
			 		this.spd.y=v_input*d_full
		 	else
		 		this.spd.x=(this.flip.x and -1 or 1)
		  		this.spd.y=0
		 	end

		 	psfx(3)
		 	freeze=2
		 	shake=6
		 	this.dash_target.x=2*sign(this.spd.x)
		 	this.dash_target.y=2*sign(this.spd.y)
		 	this.dash_accel.x=1.5
		 	this.dash_accel.y=1.5

		 	if this.spd.y<0 then
		 		this.dash_target.y*=.75
		 	end

		 	if this.spd.y!=0 then
		 		this.dash_accel.x*=0.70710678118
		 	end
		 	if this.spd.x!=0 then
		 		this.dash_accel.y*=0.70710678118
		 	end
			elseif dash and this.djump<=0 then
				psfx(9)
				init_object(smoke,this.x,this.y)
			end

		end

		-- animation
		this.spr_off+=0.25
		if not on_ground then
			if this.is_solid(input,0) then
				if level_index()==8 then
				this.spr=132
				else
				this.spr=5
				end
			else
				if level_index()==8 then
					this.spr=130
				else
					this.spr=3
				end
			end
		elseif btn(k_down) then
			if level_index()==8 then
				this.spr=133
			else
			this.spr=6
			end
		elseif btn(k_up) then
			if level_index()==8 then
				this.spr=134
			else
			this.spr=7
			end
		elseif (this.spd.x==0) or (not btn(k_left) and not btn(k_right)) then
			if level_index()==8 then
				this.spr=128
			else
			this.spr=1
			end
		else
			if level_index()==8 then
				this.spr=128+this.spr_off%4
			else
			this.spr=1+this.spr_off%4
			end
		end

		-- next level
		if this.y<-4 and level_index()<10 then
			if buttons==0 and chest==0 then
				next_room()
			else
				draw=function(this)
					rectfill(32,2,96,31,0)
				end
				this.y=-4
				if this.spd.y < 0 then this.spd.y = 0 end
			end
		end

		-- was on the ground
		this.was_on_ground=on_ground

	end, --<end update loop

	draw=function(this)

		-- clamp in screen
		if this.x<-1 or this.x>121 then
			this.x=clamp(this.x,-1,121)
			this.spd.x=0
		end

		set_hair_color(this.djump)
		--draw_hair(this,this.flip.x and -1 or 1)
		spr(this.spr,this.x,this.y,1,1,this.flip.x,this.flip.y)
		unset_hair_color()
	end
}

psfx=function(num)
 if sfx_timer<=0 then
  sfx(num)
 end
end


-- create_hair=function(obj)
-- 	obj.hair={}
-- 	for i=0,5 do
-- 		add(obj.hair,{x=obj.x,y=obj.y,size=max(1,min(1,1-i))})
-- 	end
-- end

set_hair_color=function(djump)
	pal(8,8)
end

-- draw_hair=function(obj,facing)
-- 	local last={x=obj.x+4-facing*2,y=obj.y+(btn(k_down) and 1 or 3)}
-- 	foreach(obj.hair,function(h)
-- 		h.x+=(last.x-h.x)/1.5
-- 		h.y+=(last.y+0.5-h.y)/1.5
-- 		circfill(h.x,h.y,h.size,8)
-- 		last=h
-- 	end)
-- end

unset_hair_color=function()
	pal(8,8)
end

player_spawn = {
	tile=1,
	init=function(this)
	 sfx(4)
	 	if level_index()==8 then
				this.spr=130
			else
				this.spr=3
		 end
		this.target= {x=this.x,y=this.y}
		this.y=128
		this.spd.y=-4
		this.state=0
		this.delay=0
		this.solids=false
	end,
	update=function(this)
		-- jumping up
		if this.state==0 then
			if this.y < this.target.y+16 then
				this.state=1
				this.delay=3
			end
		-- falling
		elseif this.state==1 then
			this.spd.y+=0.5
			if this.spd.y>0 and this.delay>0 then
				this.spd.y=0
				this.delay-=1
			end
			if this.spd.y>0 and this.y > this.target.y then
				this.y=this.target.y
				this.spd = {x=0,y=0}
				this.state=2
				this.delay=5
				shake=5
				init_object(smoke,this.x,this.y+4)
				sfx(5)
			end
		-- landing
		elseif this.state==2 then
			this.delay-=1
				if level_index()==8 then
				this.spr=133
				else
				this.spr=6
				end
			if this.delay<0 then
				destroy_object(this)
				init_object(player,this.x,this.y)
			end
		end
	end,
	draw=function(this)
		set_hair_color(max_djump)
		--draw_hair(this,1)
		spr(this.spr,this.x,this.y,1,1,this.flip.x,this.flip.y)
		unset_hair_color()
	end
}
add(types,player_spawn)

spring = {
	tile=18,
	init=function(this)
		this.hide_in=0
		this.hide_for=0
	end,
	update=function(this)
		if this.hide_for>0 then
			this.hide_for-=1
			if this.hide_for<=0 then
				this.spr=18
				this.delay=0
			end
		elseif this.spr==18 then
			local hit = this.collide(player,0,0)
			if hit ~=nil and hit.spd.y>=0 then
				this.spr=19
				hit.y=this.y-4
				hit.spd.x*=0.2
				hit.spd.y=-3
				hit.djump=max_djump
				this.delay=10
				init_object(smoke,this.x,this.y)

				-- breakable below us
				local below=this.collide(fall_floor,0,1)
				if below~=nil then
					break_fall_floor(below)
				end

				psfx(8)
			end
		elseif this.delay>0 then
			this.delay-=1
			if this.delay<=0 then
				this.spr=18
			end
		end
		-- begin hiding
		if this.hide_in>0 then
			this.hide_in-=1
			if this.hide_in<=0 then
				this.hide_for=60
				this.spr=0
			end
		end
	end
}
add(types,spring)

function break_spring(obj)
	obj.hide_in=15
end

bird = {
	tile=148,
	draw=function(this)
		spr(148+(frames/9)%2,this.x,this.y)
	end
}
add(types,bird)

bat = {
	tile=146,
	draw=function(this)
		spr(146+(frames/9)%2,this.x,this.y)
	end
}
add(types,bat)

tiger = {
	tile=151,
	draw=function(this)
		spr(151+(frames/10)%2,this.x,this.y)
	end
}
add(types,tiger)




ghost = {
	tile=135,
	draw=function(this)
		spr(135+(frames/10)%2,this.x,this.y)
	end
}
add(types,ghost)

lava = {
	tile=67,
	draw=function(this)
		spr(67+(frames/5)%2,this.x,this.y)
	end
}
add(types,lava)



balloon = {
	tile=22,
	init=function(this)
		this.offset=rnd(1)
		this.start=this.y
		this.timer=0
		this.hitbox={x=-1,y=-1,w=10,h=10}
	end,
	update=function(this)
		if this.spr==22 then
			this.offset+=0.01
			this.y=this.start+sin(this.offset)*2
			local hit = this.collide(player,0,0)
			if hit~=nil and hit.djump<max_djump then
				psfx(6)
				init_object(smoke,this.x,this.y)
				hit.djump=max_djump
				this.spr=0
				this.timer=60
			end
		elseif this.timer>0 then
			this.timer-=1
		else
		 psfx(7)
		 init_object(smoke,this.x,this.y)
			this.spr=22
		end
	end,
	draw=function(this)
		if this.spr==22 then
			spr(13+(this.offset*8)%3,this.x,this.y+6)
			spr(this.spr,this.x,this.y)
		end
	end
}
add(types,balloon)

stars = {
	tile=85,
	init=function(this)
		this.offset=rnd(1)
		this.start=this.y
		this.timer=0
		this.hitbox={x=-1,y=-1,w=10,h=10}
	end,
	update=function(this)
		if this.spr==85 then
			this.offset+=0.01
			this.y=this.start+sin(this.offset)*2
			local hit = this.collide(player,0,0)
			if hit~=nil and hit.djump<max_djump then
				psfx(6)
				init_object(smoke,this.x,this.y)
				hit.djump=max_djump
				this.spr=0
				this.timer=60
			end
		elseif this.timer>0 then
			this.timer-=1
		else
		 psfx(7)
		 init_object(smoke,this.x,this.y)
			this.spr=85
		end
	end,
	draw=function(this)
		if this.spr==85 then
			spr(this.spr,this.x,this.y)
		end
	end
}
add(types, stars)

fall_floor = {
	tile=23,
	init=function(this)
		this.state=0
		this.solid=true
	end,
	update=function(this)
		-- idling
		if this.state == 0 then
			if this.check(player,0,-1) or this.check(player,-1,0) or this.check(player,1,0) then
				break_fall_floor(this)
			end
		-- shaking
		elseif this.state==1 then
			this.delay-=1
			if this.delay<=0 then
				this.state=2
				this.delay=60--how long it hides for
				this.collideable=false
			end
		-- invisible, waiting to reset
		elseif this.state==2 then
			this.delay-=1
			if this.delay<=0 and (not this.check(player,0,0)) and (not this.check(g,0,0)) then
				psfx(7)
				this.state=0
				this.collideable=true
				init_object(smoke,this.x,this.y)
			end
		end
	end,
	draw=function(this)
		if this.state!=2 then
			if this.state!=1 then
				spr(23,this.x,this.y)
			else
				spr(23+(15-this.delay)/5,this.x,this.y)
			end
		end
	end
}
add(types,fall_floor)

function break_fall_floor(obj)
 if obj.state==0 then
 	psfx(15)
		obj.state=1
		obj.delay=15--how long until it falls
		init_object(smoke,obj.x,obj.y)
		local hit=obj.collide(spring,0,-1)
		if hit~=nil then
			break_spring(hit)
		end
	end
end

smoke={
	init=function(this)
		this.spr=29
		this.spd.y=-0.1
		this.spd.x=0.3+rnd(0.2)
		this.x+=-1+rnd(2)
		this.y+=-1+rnd(2)
		this.flip.x=maybe()
		this.flip.y=maybe()
		this.solids=false
	end,
	update=function(this)
		this.spr+=0.2
		if this.spr>=32 then
			destroy_object(this)
		end
	end
}

fruit={

	if_not_fruit=true,
	init=function(this)
	if level_index()==0 then
		this.spr=26 --banana
	elseif level_index()==1 then
		this.spr=87 --nutterbutter
	elseif level_index()==2 then
		this.spr=88 --candycorn
	elseif level_index()==3 then
		this.spr=73 --gelato
	elseif level_index()==4 then
		this.spr=75 --jalapeno
	elseif level_index()==5 then
		this.spr=74 --coffee
	elseif level_index()==6 then
		this.spr=76 --cake
	elseif level_index()==7 then
		this.spr=86 --heart
		elseif level_index()==8 then
		this.spr=102 --moon
	elseif level_index()==9 then
		this.spr=94 --ring

	end
		this.start=this.y
		this.off=0
	end,



	update=function(this)
	 local hit=this.collide(player,0,0)
		if hit~=nil then
		 hit.djump=max_djump
			sfx_timer=20
			sfx(13)
			got_fruit[1+level_index()] = true
			init_object(lifeup,this.x,this.y)
			destroy_object(this)
		end
		this.off+=1
		this.y=this.start+sin(this.off/40)*2.5
	end
}
add(types,fruit)

fly_fruit={
	tile=119,
	init=function(this)
		this.start=this.y
		this.fly=false
		this.step=0.5
		this.solids=false
		this.sfx_delay=8
	end,
	update=function(this)
			this.step+=0.05
			this.spd.y=sin(this.step)*0.5

	end,
	draw=function(this)

		if this.check(player,-58,80) then
			this.text="the clouds can hold you#up! you are almost done#now, come on i'll give#you a boost!"
			if this.index<#this.text then
			 this.index+=0.6
				if this.index>=this.last+1 then
				 this.last+=1
				 sfx(35)
				end
		end
			this.off={x=4,y=50}
			for i=1,this.index do
				if sub(this.text,i,i)~="#" then
					rectfill(this.off.x-2,this.off.y-2,this.off.x+7,this.off.y+6 ,0)
					print(sub(this.text,i,i),this.off.x,this.off.y,11)
					this.off.x+=5
						this.spr=119+(frames/5)%2
	 				spr(this.spr,this.x,this.y)

				else
					this.off.x=8
					this.off.y+=7
				end

			end

			else
			this.index=0
			this.last=0
						this.spr=119
	 				spr(this.spr,this.x,this.y)
		end

		local off=0
		if not this.fly then
			local dir=sin(this.step)
			if dir<0 then
				off=1+max(0,sign(this.y-this.start))
			end
		else
			off=(off+0.25)%3
		end
		spr(45+off,this.x-6,this.y-2,1,1,true,false)
		spr(this.spr,this.x,this.y)
		spr(45+off,this.x+6,this.y-2)
	end
}
add(types,fly_fruit)

lifeup = {
	init=function(this)
		this.spd.y=-0.25
		this.duration=30
		this.x-=2
		this.y-=4
		this.flash=0
		this.solids=false
		chest-=1
	end,
	update=function(this)
		this.duration-=1
		if this.duration<= 0 then
			destroy_object(this)
		end
	end,
	draw=function(this)
		this.flash+=0.5
	if level_index()==0 then
		print("banana!",this.x-2,this.y,7+this.flash%2)
	elseif level_index()==1 then
		print("nutter butter!",this.x+5,this.y,7+this.flash%2)
	elseif level_index()==2 then
		print("candy corn!",this.x-5,this.y,7+this.flash%2)
	elseif level_index()==3 then
		print("gelato!",this.x-5,this.y,7+this.flash%2)
	elseif level_index()==4 then
		print("jalapeno!",this.x-5,this.y,7+this.flash%2)
	elseif level_index()==5 then
		print("caffeinated!",this.x+8,this.y,7+this.flash%2)
	elseif level_index()==6 then
		print("cake is truth!",this.x-20,this.y,7+this.flash%2)
	elseif level_index()==7 then
		print("i love you!",this.x-20,this.y,7+this.flash%2)
	elseif level_index()==8 then
		print("space rock!",this.x-24,this.y,7+this.flash%2)
	elseif level_index()==9 then
		print("she said yes!",this.x-30,this.y,7+this.flash%2)
		if_not_fruit=true
		music(-1)
		music(24,500,7)--high energy
		end
	end
}

dance = {
	tile=160,
	draw=function(this)
	spr(160,this.x,this.y)
	if if_not_fruit then

		this.spr=161+(frames/4)%3
		spr(this.spr,this.x,this.y)
	end
	end
}
add(types,dance)


collision_ver=function(this, that)

	local hit = this.collide(player,0,0) or this.collide(push_wall,0,0)
	if hit!=nil and hit.dash_effect_time>3 and hit.dash_target.y*that > 0 then
		this.dash_target={x=0,y=sign(hit.dash_target.y)}
		this.spd.y=this.dash_target.y
		if(hit.type==player) then
			hit.spd.x=hit.dash_target.x
			hit.spd.y=-sign(hit.dash_target.y)*2
		end

		hit.dash_time=-1
		hit.dash_effect_time=1
		this.dash_effect_time=10

		init_object(smoke,this.x,this.y)
		shake=4 > shake and 3 or shake
	end

end

collision_hor=function(this, that)

	local hit = this.collide(player,0,0) or this.collide(push_wall,0,0)
	if hit!=nil and hit.dash_effect_time>3 and hit.dash_target.x*that > 0 then
		this.dash_target={x=sign(hit.dash_target.x),y=0}
		this.spd.x=this.dash_target.x
		if(hit.type==player) then
			hit.spd.y=hit.dash_target.y
			if(hit.spd.y<0) hit.spd.y/=0.75
			hit.spd.x=-sign(hit.dash_target.x)*2
		end

		hit.dash_time=-1
		hit.dash_effect_time=1
		this.dash_effect_time=10

		init_object(smoke,this.x,this.y)
		shake=4 > shake and 3 or shake
	end

end

push_wall = {
	tile=70,
	init=function(this)
		this.lastx=this.x
		this.dash_time = 1
		this.dash_effect_time = 10
		this.dash_target={x=0,y=0}
	end,

	update=function(this)

		this.hitbox={x=0,y=-1,w=8,h=9} -- above
		collision_ver(this,1)

		this.hitbox={x=0,y=0,w=8,h=9} -- below
		collision_ver(this,-1)

		this.hitbox={x=-1,y=0,w=9,h=8} -- left
		collision_hor(this,1)

		this.hitbox={x=0,y=0,w=9,h=8} -- right
		collision_hor(this,-1)

		this.hitbox={x=0,y=0,w=8,h=8}

		if not this.check(player,0,0) then
			local hit=this.collide(player,0,-1)
			if hit~=nil then
				hit.move_x(this.x-this.lastx,1)
			end
		end
		this.lastx=this.x

		if this.spd.x!=0 or this.spd.y!=0 then
			if rnd(1) < 0.3 then init_object(smoke,this.x,this.y) end
		end

	end,

	draw=function(this)

		if level_index()==3 then
	--talk
		this.text="#...sorry to be blocking#you, i think i'm frozen#you're going to have#to push me :(#"
			if this.check(player,-4,0) then
			if this.index<#this.text then
			 this.index+=0.6
				if this.index>=this.last+1 then
				 this.last+=1
				 sfx(35)
				 this.spr=89+(frames/4)%2
				 spr(this.spr,this.x,this.y)
				end
			end
			this.off={x=1,y=10}
			for i=1,this.index do
				if sub(this.text,i,i)~="#" then
					rectfill(this.off.x-2,this.off.y-2,this.off.x+7,this.off.y+6 ,0)
					print(sub(this.text,i,i),this.off.x,this.off.y,11)
					this.off.x+=5
				else
					this.off.x=8
					this.off.y+=7
				end
			end
			else
			this.index=0
			this.last=0
		end

		end



		-- clamp in screen
		if this.x<0 or this.x>120 then
			this.x=clamp(this.x,0,120)
			this.spd.x=0
		end
		if this.y<0 or this.y>120 then
			this.y=clamp(this.y,0,120)
			this.spd.y=0
		end
		if level_index()==3 then
		spr(70,this.x,this.y)
		else
		spr(69,this.x,this.y)
		end
	end
}
add(types,push_wall)

push_button = {
	tile=71,

	init=function(this)
		buttons += 1
	end,

	update=function(this)

		if this.check(push_wall,0,0) then
			psfx(63)
			destroy_object(this)
			buttons-=1
			init_object(smoke,this.x-2,this.y-2)
			init_object(smoke,this.x-2,this.y+2)
			init_object(smoke,this.x+2,this.y-2)
			init_object(smoke,this.x+2,this.y+2)
			init_object(key,this.x+8,this.y+40)

		end

	end
}
add(types,push_button)

fake_wall = {
	tile=64,
	if_not_fruit=true,
	update=function(this)
		this.hitbox={x=-1,y=-1,w=18,h=18}
		local hit = this.collide(player,0,0)
		if hit~=nil and hit.dash_effect_time>0 then
			hit.spd.x=-sign(hit.spd.x)*1.5
			hit.spd.y=-1.5
			hit.dash_time=-1
			sfx_timer=20
			sfx(16)
			destroy_object(this)
			init_object(smoke,this.x,this.y)
			init_object(smoke,this.x+8,this.y)
			init_object(smoke,this.x,this.y+8)
			init_object(smoke,this.x+8,this.y+8)
		end
		this.hitbox={x=0,y=0,w=16,h=16}
	end,
	draw=function(this)
		spr(64,this.x,this.y)
		spr(65,this.x+8,this.y)
		spr(80,this.x,this.y+8)
		spr(81,this.x+8,this.y+8)
	end
}
add(types,fake_wall)

key={
	tile=8,
	if_not_fruit=true,
	update=function(this)
		local was=flr(this.spr)
		this.spr=9+(sin(frames/30)+0.5)*1
		local is=flr(this.spr)
		if is==10 and is!=was then
			this.flip.x=not this.flip.x
		end
		if this.check(player,0,0) then
			sfx(23)
			sfx_timer=10
			destroy_object(this)
			has_key=true
		end
	end

}
add(types,key)

chest={
	tile=20,
	if_not_fruit=true,
	init=function(this)
		chest+=1
		this.x-=1
		this.start=this.x
		this.timer=20
	end,
	draw=function(this)
	if level_index()~=7 and
	level_index()~=9 then
		spr(20,this.x,this.y)
	else
		spr(0,this.x,this.y)
	end
	end,

	update=function(this)
		if has_key then
			this.timer-=1
			this.x=this.start-1+rnd(3)
			if this.timer<=0 then
			 sfx_timer=20
			 sfx(16)
				init_object(fruit,this.x,this.y-4)
				destroy_object(this)
			end
		end
	end
}
add(types,chest)

platform={
	init=function(this)
		this.x-=4
		this.solids=false
		this.hitbox.w=16
		this.last=this.x
	end,
	update=function(this)
		this.spd.x=this.dir*0.65
		if this.x<-16 then this.x=128
		elseif this.x>128 then this.x=-16 end
		if not this.check(player,0,0) then
			local hit=this.collide(player,0,-1)
			if hit~=nil then
				hit.move_x(this.x-this.last,1)
			end
		end
		this.last=this.x
	end,
	draw=function(this)
		spr(11,this.x,this.y-1)
		spr(12,this.x+8,this.y-1)
	end
}


portal_bots={
	init=function(this)
	this.spr_off=0 end,
	tile=92,
	last=0,
	draw=function(this)
		this.text="#i can't hear you#... i love you...#what!?   #...oh...my...shit...#it's okay i can-#uugghhhhh noooooo#i solved the puzzle!"
		if this.check(player,4,0) then
			if this.index<#this.text then
			 this.index+=0.6
				if this.index>=this.last+1 then
				 this.last+=1
				 sfx(35)
				 end
			end
			this.off={x=8,y=36}
			local textcolor=12
			for i=1,this.index do
				if sub(this.text,i,i)~="#" then
					rectfill(this.off.x-2,this.off.y-2,this.off.x+7,this.off.y+6 ,7)
					print(sub(this.text,i,i),this.off.x,this.off.y,textcolor)
					this.off.x+=5
				else
					if textcolor==9 then
						textcolor=12
					elseif textcolor==12 then
						textcolor=9
					end
					this.off.x=8
					this.off.y+=7
				end
			end

		else
			this.index=0
			this.last=0
		end
	end
}
add(types,portal_bots)

ghost={
	init=function(this)
	this.spr_off=0 end,
	tile=89,
	last=0,
	draw=function(this)
	if is_title() then
		this.text="#hello world!#you found a glitch!"
	elseif level_index()==0 then
		this.text="#to diagonal double jump#press and hold >+^+❎#collect the + to unlock#the surprise in the#chest and the next level#is always up top!"
	elseif level_index()==1 then
		this.text="#you need to get the#prize before you#can exit! walljump#to the top, break the#boulder with ❎#and you're out of#this cave!"
	elseif level_index()==2 then
		this.text="#balloons give you an#extra power jump,#give it a shot"
	elseif level_index()==4 then
		this.spr=121+(frames/5)%2
	 spr(this.spr,this.x,this.y)
		this.text="#you shouldn't be #standing this close#to lava....      ...#.....................#don't worry i can#handle it"
	elseif level_index()==5 then--dark land
		this.text="#i can barely see#anything! break some of#these boulders for us#let's get out of here!"
	elseif level_index()==6 then--portal land
		this.text="#push the companion#cube to the button to#get the +!"
	elseif level_index()==8 then--space land
		this.spr=144
	 spr(this.spr,this.x,this.y)
		this.text="#these stars are fuel#for your jetpack! you#are just about done"
	else
		this.text=""
	end
		if this.check(player,-6,0) then
			if this.index<#this.text then
			 this.index+=0.6
				if this.index>=this.last+1 then
				 this.last+=1
				 sfx(35)
				 if level_index==8 then
				 	this.spr=144+(frames/4)%2
	 				spr(this.spr,this.x,this.y)
				 else
				 	this.spr=89+(frames/4)%2
				 	spr(this.spr,this.x,this.y)
					end
				end
			end
			if level_index()==0 or
						level_index()==1 then
				this.off={x=0,y=0}
			else
				this.off={x=8,y=46}
			end
			for i=1,this.index do
				if sub(this.text,i,i)~="#" then
					rectfill(this.off.x-2,this.off.y-2,this.off.x+7,this.off.y+6 ,0)
					print(sub(this.text,i,i),this.off.x,this.off.y,11)
					this.off.x+=5
				else
					this.off.x=8
					this.off.y+=7
				end
			end

		else
			this.index=0
			this.last=0
		end
	end
}
add(types,ghost)

big_chest={
	tile=191,
	init=function(this)
		this.state=0
		this.hitbox.w=16
	end,
	draw=function(this)
		if this.state==0 then
			local hit=this.collide(player,-8,0)
			if hit~=nil and hit.is_solid(0,1) then
				music(-1,500,7)
				sfx(37)
				pause_player=true
				hit.spd.x=0
				hit.spd.y=0
				this.state=1
				init_object(smoke,this.x,this.y)
				init_object(smoke,this.x+8,this.y)
				this.timer=60
				this.particles={}
			end
		elseif this.state==1 then
			this.timer-=1
		 shake=5
		 flash_bg=true
			if this.timer<=45 and count(this.particles)<50 then
				add(this.particles,{
					x=1+rnd(14),
					y=0,
					h=32+rnd(32),
					spd=8+rnd(8)
				})
			end
			if this.timer<0 then
				this.state=2
				this.particles={}
				flash_bg=true
				--new_bg=true -- !!!
				--init_object(orb,this.x+4,this.y+4)
				music_timer = 200 -- !!!
				init_object(fruit,this.x+4,this.y-4)
				init_object(smoke,this.x+4,this.y-4)
				pause_player=false
			end
			foreach(this.particles,function(p)
				p.y+=p.spd
				line(this.x+p.x,this.y+8-p.y,this.x+p.x,min(this.y+8-p.y+p.h,this.y+8),7)
			end)
		end
	end
}
add(types,big_chest)


room_title = {
	init=function(this)
		this.delay=5
 end,
	draw=function(this)
		this.delay-=1
		if this.delay<-30 then
			destroy_object(this)
		elseif this.delay<0 then

			rectfill(24,58,104,70,0)

			if level_index()==0 then
				print("hello world",45,62,7)
			elseif level_index()==1 then
				print("cave story",45,62,7)
			elseif level_index()==2 then
				print("you're so sweet",35,62,7)
				elseif level_index()==3 then
				print("such ice",47,62,7)
				elseif level_index()==4 then
				print("so spice",50,62,7)
			elseif level_index()==5 then
				print("hello darkness...",32,62,7)
			elseif level_index()==6 then
				print("portal 3",50,62,7)
			elseif level_index()==7 then
				print("rim of the sky",37,62,7)
			elseif level_index()==8 then
				print("reach for the stars",27,62,7)
			elseif level_index()==9 then
				print("the question",40,62,7)
			else
				local level=(1+level_index())
				print(level.." level",52,62,7)
			end
			--print("---",86,64-2,13)

			draw_time(4,4)
		end
	end
}

-- object functions --
-----------------------

function init_object(type,x,y)
	if type.if_not_fruit~=nil and got_fruit[1+level_index()] then
		return
	end
	local obj = {}
	obj.type = type
	obj.collideable=true
	obj.solids=true

	obj.spr = type.tile
	obj.flip = {x=false,y=false}

	obj.x = x
	obj.y = y
	obj.hitbox = { x=0,y=0,w=8,h=8 }

	obj.spd = {x=0,y=0}
	obj.rem = {x=0,y=0}

	obj.is_solid=function(ox,oy)
		if oy>0 and not obj.check(platform,ox,0) and obj.check(platform,ox,oy) then
			return true
		end
		return solid_at(obj.x+obj.hitbox.x+ox,obj.y+obj.hitbox.y+oy,obj.hitbox.w,obj.hitbox.h)
		 or obj.check(fall_floor,ox,oy)
		 or obj.check(fake_wall,ox,oy)
		 or obj.check(push_wall,ox,oy)
	end

	obj.is_ice=function(ox,oy)
		return ice_at(obj.x+obj.hitbox.x+ox,obj.y+obj.hitbox.y+oy,obj.hitbox.w,obj.hitbox.h)
	end

	obj.collide=function(type,ox,oy)
		local other
		for i=1,count(objects) do
			other=objects[i]
			if other ~=nil and other.type == type and other != obj and other.collideable and
				other.x+other.hitbox.x+other.hitbox.w > obj.x+obj.hitbox.x+ox and
				other.y+other.hitbox.y+other.hitbox.h > obj.y+obj.hitbox.y+oy and
				other.x+other.hitbox.x < obj.x+obj.hitbox.x+obj.hitbox.w+ox and
				other.y+other.hitbox.y < obj.y+obj.hitbox.y+obj.hitbox.h+oy then
				return other
			end
		end
		return nil
	end

	obj.check=function(type,ox,oy)
		return obj.collide(type,ox,oy) ~=nil
	end

	obj.move=function(ox,oy)
		local amount
		-- [x] get move amount
 	obj.rem.x += ox
		amount = flr(obj.rem.x + 0.5)
		obj.rem.x -= amount
		obj.move_x(amount,0)

		-- [y] get move amount
		obj.rem.y += oy
		amount = flr(obj.rem.y + 0.5)
		obj.rem.y -= amount
		obj.move_y(amount)
	end

	obj.move_x=function(amount,start)
		if obj.solids then
			local step = sign(amount)
			for i=start,abs(amount) do
				if not obj.is_solid(step,0) then
					obj.x += step
				else
					obj.spd.x = 0
					obj.rem.x = 0
					break
				end
			end
		else
			obj.x += amount
		end
	end

	obj.move_y=function(amount)
		if obj.solids then
			local step = sign(amount)
			for i=0,abs(amount) do
	 		if not obj.is_solid(0,step) then
					obj.y += step
				else
					obj.spd.y = 0
					obj.rem.y = 0
					break
				end
			end
		else
			obj.y += amount
		end
	end

	add(objects,obj)
	if obj.type.init~=nil then
		obj.type.init(obj)
	end
	return obj
end

function destroy_object(obj)
	del(objects,obj)
end

function kill_player(obj)
	sfx_timer=12
	sfx(0)
	deaths+=1
	shake=10
	destroy_object(obj)
	dead_particles={}
	for dir=0,7 do
		local angle=(dir/8)
		add(dead_particles,{
			x=obj.x+4,
			y=obj.y+4,
			t=10,
			spd={
				x=sin(angle)*3,
				y=cos(angle)*3
			}
		})
		restart_room()
	end
end

-- room functions --
--------------------

function restart_room()
	will_restart=true
	delay_restart=15
end

function next_room()

	if level_index()==-1 then
		music(0,500,7)--first level
	elseif level_index()==0 then
		music(10,500,7)--heavier
	elseif level_index()==1 then
		music(0,500,7)--first level
	elseif level_index()==2 then
		music(20,500,7)--high energy
	elseif level_index()==4 then
		music(10,500,7)--heavier
	elseif level_index()==5 then
		music(40,500,7)--intro screen
	elseif level_index()==6 then
		music(30,500,7)--sky wind calm
 elseif level_index()==7 then
		music(-1) --no music
 elseif level_index()==8 then
		music(30,500,7)--first level
	elseif level_index()==9 then
		music(-1)
 end

	if room.x==7 then
		load_room(0,room.y+1)
	else
		load_room(room.x+1,room.y)
	end
end

function prev_room() -- for cheating
	if room.x==0 then
		load_room(7,room.y-1)
	else
		load_room(room.x-1,room.y)
	end
end

function load_room(x,y)
	has_dashed=false
	has_key=false
	buttons = 0
	chest=0

	--remove existing objects
	foreach(objects,destroy_object)

	--current room
	room.x = x
	room.y = y

	-- entities
	for tx=0,15 do
		for ty=0,15 do
			local tile = mget(room.x*16+tx,room.y*16+ty);
			if tile==11 then
				init_object(platform,tx*8,ty*8).dir=-1
			elseif tile==12 then
				init_object(platform,tx*8,ty*8).dir=1
			else
				foreach(types,
				function(type)
					if type.tile == tile then
						init_object(type,tx*8,ty*8)
					end
				end)
			end
		end
	end

	if not is_title() then
		init_object(room_title,0,0)
	end
end

-- update function --
-----------------------

function _update()
	frames=((frames+1)%30)
	if frames==0 and level_index()<30 then
		seconds=((seconds+1)%60)
		if seconds==0 then
			minutes+=1
		end
	end

	if music_timer>0 then
	 music_timer-=1
	end

	if sfx_timer>0 then
	 sfx_timer-=1
	end

	-- cancel if freeze
	if freeze>0 then freeze-=1 return end

	-- screenshake
	if shake>0 then
		shake-=1
		camera()
		if shake>0 then
			camera(-2+rnd(5),-2+rnd(5))
		end
	end

	-- restart (soon)
	if will_restart and delay_restart>0 then
		delay_restart-=1
		if delay_restart<=0 then
			will_restart=false
			load_room(room.x,room.y)
		end
	end

	-- update each object
	foreach(objects,function(obj)
		obj.move(obj.spd.x,obj.spd.y)
		if obj.type.update~=nil then
			obj.type.update(obj)
		end
	end)

	-- start game
	if is_title() then
		if not start_game and (btn(k_jump) or btn(k_dash)) then
			music(-1)
			start_game_flash=40
			start_game=true
			sfx(38)
		end
		if start_game then
			start_game_flash-=1
			if start_game_flash<=-30 then
				begin_game()
			end
		end
	end

	-- cheats!

	if btnp(1, 1) then next_room() end
	if btnp(0, 1) then prev_room() end

end

-- drawing functions --
-----------------------
function _draw()
	if freeze>0 then return end

	-- reset all palette values
	pal()
		palt(14, true) --pink transparent
	palt(0, false) --black useable

	--forest land
	if level_index()==0 then
	-- pal(12,3) -- sky color

	--lava land
	elseif level_index()==4 then
	pal(12,5) --sky color
	pal(3,2) -- bulk grass
	pal(11,8) --liner grass
	pal(4,9) --tree trunks
	pal(13,11) --lizard green


	--ice land
	elseif level_index()==3 then
	pal(12,1) --sky color
	pal(3,12) -- bulk grass
	pal(11,7) --liner grass
	pal(4,5) --tree trunks

	--desert land
	elseif level_index()==1 then
	pal(12,13) --sky color
	pal(3,4) -- bulk grass
	pal(11,9) --liner grass
	pal(4,2) --tree trunks

	--dark land
	elseif level_index()==5 then
	pal(12,0) --sky color
	pal(3,0) -- bulk grass
	pal(11,1) --liner grass
	pal(4,1) --tree trunks

	--portal land
	elseif level_index()==6 then
	pal(3,7) -- bulk grass
	pal(11,7) --liner grass
	pal(4,7) --tree trunks

	--candy land
	elseif level_index()==2 then
	pal(3,14) -- bulk grass
	pal(11,10) --liner grass
	pal(6,15) --clouds
	pal(4,13) --tree trunks

	--sky land
	elseif level_index()==7 then
	pal(3,6) -- bulk grass
	pal(11,7) --liner grass
	pal(4,12) --tree trunks

	--space land
	elseif level_index()==8 then
	pal(3,1) -- bulk grass
	pal(11,7) --liner grass
	pal(4,12) -- trunks

	--engaged!!!!!!!!!!!!!!
	elseif level_index()==9 then
	pal(12,1) --sky color
	pal(3,0) -- bulk grass
	pal(11,7) --liner grass

	end

	-- start game flash
	if start_game then
		local c=10
		local d=10
		if start_game_flash>10 then
			if frames%10<5 then
				c=7
			end
		elseif start_game_flash>5 then
			c=2
		elseif start_game_flash>0 then
			c=1
		else
			c=0
		end
		if start_game_flash>0 then
			-- nothing yet
		elseif start_game_flash>-5 then
			d=2
		elseif start_game_flash>-10 then
			d=1
		else
			d=0
		end

		if c<10 then
			pal(6,c)
			pal(12,c)
			pal(13,c)
			pal(5,c)
			pal(1,c)
			pal(7,c)
		end
		if d<10 then
			pal(8,d)
			pal(14,d)
		end

	end

	-- clear screen
	local bg_color=12
	if level_index()==6 then
		bg_col=6
	elseif level_index()==8 then
		bg_col=0
	else
		bg_col = 12
	end

	if flash_bg then
		bg_col = frames/5
	elseif new_bg~=nil then
		bg_col=2
	end
	rectfill(0,0,128,128,bg_col)

	-- clouds
	if not is_title() and
	level_index()~=7 and
	level_index()~=5 and
	level_index()~=1 and
	level_index()~=8 and
	level_index()~=9 and
	level_index()~=6
	 then
		foreach(clouds, function(c)
			c.x += c.spd
			rectfill(c.x,c.y,c.x+c.w,c.y+4+(1-c.w/64)*12,new_bg~=nil and 6 or 6)
			if c.x > 128 then
				c.x = -c.w
				c.y=rnd(128-8)
			end
		end)
	end

	-- draw bg terrain
	map(room.x * 8,room.y * 8,0,0,16,16,4)

	-- platforms/big chest
	foreach(objects, function(o)
		if o.type==platform or o.type==big_chest then
			draw_object(o)
		end
	end)

	-- draw terrain
	local off=is_title() and -4 or 0
	map(room.x*16,room.y * 16,off,0,16,16,2)

	-- draw objects
	foreach(objects, function(o)
		if o.type~=platform and o.type~=big_chest then
			draw_object(o)
		end
	end)

	-- draw fg terrain
	map(room.x * 16,room.y * 16,0,0,16,16,8)

	-- turn off the particles!!!!!
	if level_index()==5
	or level_index()==6 then
		-- particles on!!!!!!!!!!!!!
else
	foreach(particles, function(p)
		p.x += p.spd
		p.y += sin(p.off)
		p.off+= min(0.05,p.spd/32)
		rectfill(p.x,p.y,p.x+p.s,p.y+p.s,p.c)
		if p.x>128+4 then
			p.x=-4
			p.y=rnd(128)
		end
	end)
end

	-- dead particles
	foreach(dead_particles, function(p)
		p.x += p.spd.x
		p.y += p.spd.y
		p.t -=1
		if p.t <= 0 then del(dead_particles,p) end
		rectfill(p.x-p.t/5,p.y-p.t/5,p.x+p.t/5,p.y+p.t/5,8+p.t%2)
	end)

	-- draw outside of the screen for screenshake
	rectfill(-5,-5,-1,133,0)
	rectfill(-5,-5,133,-1,0)
	rectfill(-5,128,133,133,0)
	rectfill(128,-5,133,133,0)

	-- credits
	if is_title() then
		print("press ❎ to start!",33,2,7)
		print("game modded by localghost",22,18,7)
		print("controls: arrow keys to move",1,81,0)
		print("z to jump, x to power dash",5,87,0)
		print("or use a gamepad!",5,93,0)
	print("thanks to: daniel linssen",0,                              116,7)
	print("matt thorson & noel berry",0,122,7)


	end

	if level_index()==30 then
		local p
		for i=1,count(objects) do
			if objects[i].type==player then
				p = objects[i]
				break
			end
		end
		if p~=nil then
			local diff=min(24,40-abs(p.x+4-64))
			rectfill(0,0,diff,128,0)
			rectfill(128-diff,0,128,128,0)
		end
	end

end

function draw_object(obj)

	if obj.type.draw ~=nil then
		obj.type.draw(obj)
	elseif obj.spr > 0 then
		spr(obj.spr,obj.x,obj.y,1,1,obj.flip.x,obj.flip.y)
	end

end

function draw_time(x,y)

	local s=seconds
	local m=minutes%60
	local h=flr(minutes/60)

	rectfill(x,y,x+32,y+6,0)
	print((h<10 and "0"..h or h)..":"..(m<10 and "0"..m or m)..":"..(s<10 and "0"..s or s),x+1,y+1,7)

end

-- helper functions --
----------------------

function clamp(val,a,b)
	return max(a, min(b, val))
end

function appr(val,target,amount)
 return val > target
 	and max(val - amount, target)
 	or min(val + amount, target)
end

function sign(v)
	return v>0 and 1 or
		v<0 and -1 or 0
end

function maybe()
	return rnd(1)<0.5
end

function solid_at(x,y,w,h)
 return tile_flag_at(x,y,w,h,0)
end

function ice_at(x,y,w,h)
 return tile_flag_at(x,y,w,h,4)
end

function tile_flag_at(x,y,w,h,flag)
 for i=max(0,flr(x/8)),min(15,(x+w-1)/8) do
 	for j=max(0,flr(y/8)),min(15,(y+h-1)/8) do
 		if fget(tile_at(i,j),flag) then
 			return true
 		end
 	end
 end
	return false
end

function tile_at(x,y)
 return mget(room.x * 16 + x, room.y * 16 + y)
end

function spikes_at(x,y,w,h,xspd,yspd)
 for i=max(0,flr(x/8)),min(15,(x+w-1)/8) do
 	for j=max(0,flr(y/8)),min(15,(y+h-1)/8) do
 	 local tile=tile_at(i,j)
 	 if tile==17 and ((y+h-1)%8>=6 or y+h==j*8+8) and yspd>=0 then
 	  return true
 	 elseif tile==27 and y%8<=2 and yspd<=0 then
 	  return true
 		elseif tile==43 and x%8<=2 and xspd<=0 then
 		 return true
 		elseif tile==59 and ((x+w-1)%8>=6 or x+w==i*8+8) and xspd>=0 then
 		 return true
 		end
 	end
 end
	return false
end

function lava_at(x,y,w,h,xspd,yspd)
 for i=max(0,flr(x/8)),min(15,(x+w-1)/8) do
 	for j=max(0,flr(y/8)),min(15,(y+h-1)/8) do
 	 local tile=tile_at(i,j)
 	 if tile==83 or tile==84 or tile==67 or tile==68 then
 	  return true
 		end
 	end
 end
	return false
end
__gfx__
eeeeeeeeeeeeeeeeeeeeeeeeee00000eeee0000eeeeeeeeeeeeeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeee77e777ee777eeeeee7eeeeeee7eeeeee7eeee
eeeeeeeeee00000eee00000ee0f00000ee000000e0000eeeeeeeeeeee0ff0000eeeaaeeeeeea9eeeeeea9eeee77777767777777eeeee7eeeeeee7eeeeee7eeee
eeeeeeeee0f00000e0f00000e0ff0000e0ff0000000000eeee00000ee0f1ff10eeeaaeeeeeea9eeeeeea9eee7766666667767777eee7eeeeeeee7eeeeee7eeee
eeeeeeeee0ffff00e0ffff00eff1ff10e0fffff0000ff0eee0000000effffff0eaaaaaaeeaaaaa9eeeea9eee7677766676666677eee7eeeeeeee7eeeeee7eeee
eeeeeeeeeff1ff10eff1ff10f0ffffffeff1ff1001ff1feee0f00000e0fff1feeaaaaaaeeaaaaa9eeeea9eeeeeeeeeeeeeeeeeeeeee7eeeeeee7eeeeeeee7eee
eeeeeeeee0fffff0e0ffffffee2222eef0ffffffeffff0feeffff000ee0222eeeeeaaeeeeeea9eeeeeea9eeeeeeeeeeeeeeeeeeeeee7eeeeeee7eeeeeeee7eee
eeeeeeeeeef222eeef2222eee1eeee1ee12222eeee22221ee0f1ff00eef22feeeeeaaeeeeeea9eeeeeea9eeeeeeeeeeeeeeeeeeeeeee7eeeeee7eeeeeeee7eee
eeeeeeeeee1ee1eeee1eee1eeeeeeeeeeeeee1eeeeee1eeee012221eee1ee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7eeeeee7eeeeeeee7eee
44444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888eeb333333bb333333b3bbbebb3eeeeee4566656665eeeeeeeeeeeeeeeeeeeeeeee7eeeeeee
44444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888e3bbbbbb33bbb5bb3bee3ebebeeeeee9467656765eeeeeeeeeeeeeeeee77ee7eee7eeeee7
444ee444eeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaeeeeeeeeee878888e3bbbbbb335bb3bb33b3ee3ebeeeeeaa9677e677eeeeeeeeeeee7eeeee777eeeeeeeeeeee
44eeee44ee7eee7ee499994eeeeeeeeea998888aeeeeeeeee888888e3bbbbbb33535ebb3eeeeee33eeeeaa79e7eee7eeeeeeeeeeee777e7ee77eeeeeeeeeeeee
44eeee44ee7eee7eee5005eeeeeeeeeea988888aeeeeeee4e888888e3bbbbbb33bbbe353b3eeeeeeeeeaa799e7eee7ee4eeeeeeee777777eeeee7eeeeeeeeeee
444ee444e677e677eee55eeeeeeeeeeeaaaaaaaaeeeeee44e888888e3bbbbbb33bbb3bb3be3ee3bbeeaa799deeeeeeee44eeeeeee7ee77eeeeeee77eeeeeeeee
4444444456765676ee5005eeeeeeeeeea980088aeeeee444ee8888ee3bbbbbb33bbb5bb3be3e3eeb499999ddeeeeeeee444eeeeeeeeeeeeeeee7e77ee7eeee7e
4444444456665666eee55eeee499994ea988888aeeee4444eeeeeeeeb333333bb333333b33ee333354999deeeeeeeeee4444eeeeeeeeeeee7eeeeeeeeeeeeeee
ebbbbbbeebbbbbbbbbbbbbbbbbbbbbbebb33333333333333333333bbebbbbbbe44444444444444444444444455eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333bbbbbbbbbbb444444444444444ee4444444667eeeeeee3333eeeeeeeeeeeeeeeeeeeeeeeeee
bbb3bbbbbbbb33333bbbbbb33333bbbbbbb333333333333333333bbbbbbbbbbb44444444444444eeee44444467777eeee33b333eeee77777eeeeeeeeeeeeeeee
bb3333bbbbb33333333bb33333333bbbbbbb3333333333333333bbbbbbb33bbb4444444444444eeeeee44444666eeeeee333333eee77667eeeeeeeeeeeeeeeee
bb3333bbbb33333333333333333333bbbbbb3333333333333333bbbbbb3333bb444444444444eeeeeeee444455eeeeeee333333ee76777eee77777eeeeeeeeee
bbb33bbbbb33333333333333333333bbbbb333333333333333333bbbbb3333bb44444444444eeeeeeeeee444667eeeeee333333ee7766eeee777767ee77eeeee
bbbbbbbbbb33333333333333333333bbbbb333333333333333333bbbbb3333bb4444444444eeeeeeeeeeee4467777eeee333bb3ee7777eeeeeeeee77ee77777e
ebbbbbbebb33333333333333333333bbbb33333333333333333333bbbb3333bb444444444eeeeeeeeeeeeee4666eeeeee333bb3eeeeeeeeeeeeeeeeeeee77777
bb3333bbbb33333333333333333333bbebbbbbbbbbbbbbbbbbbbbbbebbb333bb444444444eeeeeeeeeeeeee4eeeee666e333333eeeeeeeeeeeeeeeeeeeeeeeee
bbb333bbbb33333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbb4e44444444eeeeeeeeeeee44eee77776e3b3333eeeeeeeeeeeaaeaaeeeeeeeee
bbb333bbbb33333333333333333333bbbbbb333bbbbbbbbbb333bbbbbbb33bbb4444ee44444eeeeeeeeee444eeeee766e333333eeeeeeeeeeeaaaaaeeeeeeeee
bb333bbbbb33333333333333333333bbbbb33333b3bbbb3333333bbbbb333bbb4444ee444444eeeeeeee4444eeeeee55e333b33eeeeeeeeeeeea9aeeeeeeeeee
bb333bbbbbb33333333bb33333333bbbbbb3333333bbbb3b33333bbbbb3333bb4444444444444eeeeee44444eeeee666ee3333eeeeeebeeeeeaaaaaeeeeeeeee
bbb33bbbbbbb33333bbbbbb33333bbbbbbbb333bbbbbbbbbb333bbbbbb3333bb44e44444444444eeee444444eee77776eee44eeeeeebeeeeeeaa3aaeeeeeeeee
bbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbb444444444444444ee4444444eeeee766eee44eeee3ebee3eeeeebeeeee3ee33e
bb3333bbebbbbbbbbbbbbbbbbbbbbbbeebbbbbbbbbbbbbbbbbbbbbbeebbbbbbe444444444444444444444444eeeeee55ee9999eee3e33e3eeeeebeeee33e3333
ebbbbeebbbebbbbe7777777788888899899888887555555777777777eeeeeeee33333333eeef7eeeeee5e5eeeeeeeeebeeeaeeeeeeeeeeeeeeee44444444eeee
bbbbbbbbbbbbbbbb3333333388888899888888895755557573070003e655556e3bb33333eeff77eeee5e5eeeeeeee333ee7587eee5e66e5eeeeee444444eeeee
bbbb33bbbb33bbbb33733733888898888889888855855855737fff53e5eeee5e3bb33b33effff7fee60007eeeeeee28be775777e5e6777e5eeeeee4444eeeeee
bbb3333333333bbb37337333988888888889888858888885731f71f3e5e88e5e33333333effffffee6777777eeee2883877777865e6777e5eeeeeee44eeeeeee
bb333333333333bb3337337398888888889888885888888573f70ff7e5e88e5e33333333e949494ee67777e72ee2887e6787766456777775eeeeeeeeeeeeeeee
eb333333333333be337337338888888988988899558888557f711171e5eeee5e33b33333ee9494eee6777777822887ee4668664456777775eeeeeeeeeeeeeeee
ebb3333333333bbe33337333888998898888889957588575773117f3e655556e33333b33ee4949eee67777eee8888eeee446444e56777775eeeeeeeeeeeeeeee
bbb3333333333bbb3333333388899888899888887555555773033033eeeeeeee33333333eee49eeeee677eeeeeeeeeeeee4444ee56766775eeeeeeeeeeeeeeee
bbb3333333333bbbeee44eeeeeeeeeeeeeeeeeeeeeeaeeeeeeeeeeeeee9494eeeeaaaaeeee0000eeee0000eeeeeeeeeee567775e96799779eeeeeeee4eeeeeee
ebb3333333333bbbee4444eeeeeeeeeeeeeeeeeeeeeaaeeeeeeeeeeee949494eeeaaaaeeee00000eee00000eeeeeeeee5677777596777779eee77eee4eeeeeee
eb333333333333bee444444eeeeeeeeeeeeeeeeeaaa7aaaaee8ee8eee994994eee7aaaeeeeffff5eeeffff5eeeeeeeeec676677c56777775ee7777ee4eeeeeee
bb333333333333bbe444444e8889988888888888ea7aaaaee878888ee949494eee9799eeee1ff1feee1ff1feeeeeeeee567cc775ee6776eeee9779ee4eeeeeee
bbb3333333333bbbe444444e8889988889988888eeaaaaeee887888eee9494eeee9999eeeefffff1eef00ff1eeeeeeeee677777ee5e66e5ee9eeee9e4eeeeeee
bbbb33bbbb33bbbbe444444e8888888889988888eaaaaaaeee8888eee949494eee9999eeeee11111eee11111eeeeeeeeee6666eee5eeee5ee9eeee9e4eeeeeee
bbbbbbbbbbbbbbbbe444444e8888888888888898eaaeeaaeeee88eeee994944eeee99eeeeef111feeef111feeeeeeeeee5eeee5eee9ee9eeee9ee9ee4eeeeeee
ebbbbebbbbeebbbeee4444ee9888888888888888eeeeeeeeeeeeeeeeee4944eeeee77eeeeee0ee0eeee0ee0eeeeeeeeeeceeeeceee9ee9eeeee99eee4eeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888eeeeeeeee6eee6566ee4eeeeeeeeeeeeee4333333333333333333333333333333333333333333333333eeeeeee4
eeeeeeeeeeeceeeeeeeeeeeeeeeeeeeee87788eeeeeeee66e666656e44eeeeeeeeeeee44388338833388883333883333388888833883388338888883eeeeeee4
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8788788eeeeee66665566666444eeeeeeeeee444388338833388883333883333388888833888388338888883eeeeeee4
ececececeeeceeeeececeeeeeeececec8787888eeeeee666656666654444eeeeeeee4444388338833883388333883333333883333888888333388333eeeeeee4
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8788878eeeeeee66666655654444444444444444388338833883388333883333333883333888888333388333eeeeeee4
eeeeeeeeeeeceeeeeeeceeeeeeeceeeee87778eeeeeee6e6e665566e4444444444444444388888833888888333883333333883333883888333388333eeeeeee4
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee878eeeeeee6e66ee6666ee4444444444444444332222333223322333222223322222233223322333322333eeeeeee4
eeeeeeeeeeeceeeeeeeceeeeeeeceeeeeee7eeeeeeee6666eeeeeeee4444444444444444333223333223322333222223322222233223322333322333eeeeeee4
eeeeeeeeeeeeeeee44444444bbbbbbbbbbbbbbbb44444444eeeeeeeee0000eeee0000eeeee0000e9ee0090ee444444444444444444444444eeeeeee5eeeeeeee
eeeceeeeeeeceeee44777744b07700000000000b44477444eeeeeeeee00000eee00000eee800800eee000008444444444444444444444444eeeee555eeeeeeee
eeeeeeeeeeeeeeee44447744b07000000000000b44777744eeaaaaeeeffff5eeeffff5ee9e9fff5e8effff89444444444444444444444444eee755eeeeeeeeee
eeecececececeeee44474744b07707070070777b47777774ee9999ee71ff1f7771ff1f77ee1ff1f8e91ff1fe444444444444444444444444e77775eeeeeeeeee
eeeeeeeeeeeeeeee44744744b07000700070070b44477444eeeeeeee7fffff177f00ff17e8ff8ff8e88ffff14444eeeeeeeeeeeeeeee4444777777eeeeeeeeee
eeeeeeeeeeeeeeee44444444b07707070070070b44477444eeaaaaeefe1111fefe1111feeee11911eee11811444eeeeeeeeeeeeeeeeee44497777eeeeeeeeeee
eeeeeeeeeeeeeeeeeee44eeeb00000000000000beee44eeeee9999eeee111eeeee111eeee8f918f9e9f181f844eeeeeeeeeeeeeeeeeeee449977eeeeeeeeeeee
eeeeeeeeeeeeeeeeeee44eeebbbbbbbbbbbbbbbbeee44eeeeeeeeeeee0ee0eeee0ee0eee8899988e998898984eeeeeeeeeeeeeeeeeeeeee4e97eeeeeeeeeeeee
ee7777eeee7777eeee7777eeee7777eeee777eeeeeeeeeeeee7777eeeee677eeee677eeee000000eeeddeddeeddeeeddeeeeeee77eeeeeee4444444400000000
e700007ee700007ee707007ee700007ee70007eeee7777eee700007eee67777ee67777eee000000eeedddddeeedddddeeeeeeee77eeeeeee4444444400000000
70770007707700077077000770f770077007707ee700007e70f1ff17e67070776707077ee888888eddddddddddddddddeeeeeee77eeeeeee4444444400000000
7077f0077077ff077ff1ff1770f770f77007707e707000077ffffff7e67070776707077e000000000ddeeeedd0deeeedeeeeeee77eeeeeee4444444400000000
7ff1ff177ff1ff1757ffff757ff1ff1771ff1f7e707700077f77f0f7e67777776777777ee777777eddeddeedddeeddedeeeeeee77eeeeeee4444444400000000
e7ffff7ee7ffff75ee66c6ee57ffff75e7fff75e7fffff07e777777ee67777776777777e77707077eededeedeeedeeedeeeeeee77eeeeeee4444444400000000
5e66c6e5e566c6eee7eeee7ee766c6eeee6c667ee7f1f17ee566c5eee67777776777777e77079777eeedeedeeeeededeeeeeeee77eeeeeee4444444400000000
ee7ee7eeee7eee7eeeeeeeeeeeeee7eeeeee7eeeee76667eee7e7eeee67e77e76e77e77ee770797eeeeeddeeeeeeedeeeeeeeee77eeeeeee4444444400000000
ee7777eeee7777eeeeeeeeeeee5ee5eeeaaaeeeeeeeeeee9e0ee0eeeeeeeeee9eeee9eeeee3838ee888888880000000000000000000000000000000000000000
e700007ee700007eee5ee5eeee8558eeea1aeeeeeaaaee99e9099eeeeeeeee0eeeeee0eee077830e888888880000000000000000000000000000000000000000
76ffff5776ffff57e585585eee5885ee99aaeeea9a1a9999b09b0eeeeeeeee99eeeee99e077d7830988888890000000000000000000000000000000000000000
761ff1f7761ff1f751555515e555555eeaaa999999aa99997977909009000ee009000e0e07777738988888890000000000000000000000000000000000000000
76fffff776f00ff75115511555155155eaaa9999eaaaaaaa70070707970990e7970990e7707d7707988888890000000000000000000000000000000000000000
e777777ee777777e1ee55ee151155115eeaa9999eeaaaaaae7709707070990990709909970777707999889990000000000000000000000000000000000000000
ee56c65eee56c65eeee55eee51e5ee15eeeaa99eeeeaaaaee09907900799799007997990777d7777999889990000000000000000000000000000000000000000
eee7ee7eeee7ee7eeee5eeee1eeeeee1eeeeeeeeeeeeeeee79e79eee7977990e7977990ee777777e999999990000000000000000000000000000000000000000
ee0000eeee0000eeee0000eeee0000ee00000000ee2228ee0000000000000000eeeeeeee00000000999999999999999900000000000000000000000055555555
ee00000eee00000eee00000eee00000e00000000e22cccce0000000000000000eeeeeeee00000000e99999999999999e00000000000000000000000053333335
eeffff5eee1ff15eee1ff15eeeffff5e000000008222ccce0000000000000000eeeeeeee00000000ee999999999999ee00000000000000000000000053333335
ee1ff1feeef0fffeef0000feee1ff1fe0000000088222c280000000000000000eeeeeeee00000000eee9999999999eee00000000000000000000000053333335
eef0fffeeef0ffffeefffffeeef00ffe00000000e888d88e0000000000000000eeeeeeee00000000eeee99999999eeee00000000000000000000000053333335
ef0f080eee00080eee00080eef00080f00000000e9cccde90000000000000000eeeeeeee00000000eeeee999999eeeee00000000000000000000000053333335
ee00000eef00000ee5eeefe5e500000e00000000eeddddee0000000000000000eeeeeeee00000000eeeeee9999eeeeee00000000000000000000000053333335
e5eeee05ee5eee5eeeeeeeeeeeeeee5e00000000ee9ee9ee0000000000000000eeeeeeee00000000eeeeeee99eeeeeee00000000000000000000000055555555
eeeeeeeeeeeeeeeeee00000eeee0000eeeeeeeeeeeeeeeeeee00000e000000000000000000000000998888880000000000000000000000000000000000eeeee0
ee00000eee00000ee0f00000ee000000e0000eeeeeeeeeeee0ff00000000000000000000000000008998888800000000000000000000000000000000eee0eee0
e0f00000e0f00000e0ff0000e0ff0000000000eeee00000ee0f1ff1000000000000000000000000088998888000000000000000000000000000000000e0eeeee
e0ffff00e0ffff00eff1ff10e0fffff0000ff0eee0000000effffff000000000000000000000000088899888000000000000000000000000000000000eee0eee
eff1ff10eff1ff10f0ffffffeff1ff1001ff1feee0f00000e0fff1fe000000000000000000000000888899880000000000000000000000000000000000eeeeee
e0fffff0e0ffffffee2222eef0ffffffeffff0feeffff000ee0222ee00000000000000000000000088888998000000000000000000000000000000000eee000e
eef222eeef2222eee1eeee1ee12222eeee22221ee0f1ff00eef22fee0000000000000000000000008888889900000000000000000000000000000000e00eeee0
ee1ee1eeee1eee1eeeeeeeeeeeeee1eeeeee1eeee012221eee1ee1ee0000000000000000000000008888888900000000000000000000000000000000e000ee00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a2838292
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000930000000000b480b094676500a28200
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008293000000000000000000000000a276
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008283930000000000000000c20000a382
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008222329310d3e3f341d3d3c395a38283
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083525222222222222222222232838292
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000926100a24296a6b6c6a6d6e662829200
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000930000a3132323232323232333920000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008293a39200b1b1b1b1b1b1b1a2932100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e4f47171000000000000000000a24332
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051c100000000c0000000210003
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000082838282828282828283828282435333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e4f40000000000a28292
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008300
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444444444444444444444444444cccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444c444444444444444444444ccccc
ccccccccccccccccccccccccccccccccc777c777c777cc77cc77cccccc77777cccccc777cc77cccccc77c777c777c77747774474cc4444444444444444cccccc
ccccccccccccccccccccccccccccccccc7c7c7c7c7ccc7ccc7ccccccc77c7c77cccccc7cc7c7ccccc7cccc7cc7c7d7c744744474cc444444444444444ccccccc
ccccccccccccccccccccccccccccccccc777c77cc77cc777c777ccccc777c777cccccc7cc7c7ccccc777cc7cc777d77c447444744444444444444444cccccccc
ccccccccccccccccccccccccccccccccc7ccc7c7c7ccccc7ccc7ccccc77c7c77cccccc7cc7c7ccccccc7cc7cc7c7c7c7c47444c4444444444444444ccccccccc
ccccccccccccccccccccccccccccccccc7ccc7c7c777c77cc77ccccccc77777ccccccc7cc77cccccc77ccc7cc7c7c7c7cc74447444444444444444cccccccccc
cccccccccccccccccc77c777cc777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444444444d4444ccccccccccc
cccccccccccccccc77777767777777cccccccccccccccccccccbcccccccccccccccccccf7ccccccccccccccccccccccccccc4444444444444444cccccccccccc
ccccccccccccccc7766666667767777cccccccccccccccccc333cccccccaacccccccccff77ccccccccccccccccccccccccccc444444444444444cccccccccccc
ccccccccccccccc7677766676666677cccccccccccccccccc28bcccccccaaccccccccbfff7fcccaaaacccc8cc8cccccccccccc44444444444444cccccccccccc
cccdcccccccccccccccccccccccccccccccccccccccccccc2883cccccaaaaaaccccccffffffccc9999ccc878888cccccccccccc4444444444444cccccccccccc
4ccccccccccccccccccccccccccccccccccccccccccc2cc2887ccccccaaaaaacccccc949494cccccccccc887888ccccccccccccc444444444444cccccccccccc
44cccccccccccccccccccccccccccccccccccccccccc822887cccccccccaaccccccccc9494ccccaaaacccc8888ccccccccccccccc44444444444cccccccccccc
444cccccccccccccccccccccccccccccccccccccccccc8888ccccccccccaaccccccccc4949cccc9999ccccc88ccccccccccccccccc4444444444cccccccccccc
4444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc49cccccccccccccccccccccccccccccccccc444444444cccccccccccc
44444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc444444444ccccccccccc
444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc444444444cccccccccc
4444444cccccccccccccccc77c777c777c777ccccc777cc77c77cc77cc777c77cccccc777c7c7ccccc7cccc77cc77c777c7cccc77c7c7c47744774777ccccccc
44444444cccccccccccccc7ccc7c7c777c7ccccccc777c7c7c7c7c7c7c7ccc7c7ccccc7c7c7c7ccccc7ccc7c7c7ccc7c7c7ccc7ccc7c7c7474744447cccccccc
444444444ccccccccccccc7ccc777c7c7c77cccccc7c7c7c7c7c7c7c7c77cc7c7ccccc77cc777ccccc7ccc7c7c7ccc777c7ccc7ccc777c7c747774474444cccc
4444444444cccccccccccc7c7c7c7c7c7c7ccccccc7c7c7c7c7c7c7c7c7ccc7c7ccccc7c7ccc7ccccc7ccc7c7c7ccc7c7c7ccc7c7c7c7c7c74447c474444cccc
44444444444ccccccccccc777c7c7c7c7c777ccccc7c7c77cc777c777c777c777ccccc777c777ccccc777c77ccc77c7c7c777c777c7c7c77cc7744474444cccc
444444444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc444444444cccc
4444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc444444444cccc
44444c44444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3333cccccccccccccccccccccccc4444444444cccc
44444444cc44444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc33b333cccccccccccccccccccccc44444444444cccc
44444444cc444444ccccccccccccccccccccccccccccccccccccccccccccccccccccdcccccccccccccccc333333ccccccccccccccccccccc444444444444cccc
44444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc333333cccccccccccccccccccc4444444444444cccc
444444c44444444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc333333ccccccccccccccccccc44444444444444cccc
4444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc333bb3cccccccccccccccccc444444444444444cccc
44444444444444444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc333bb3ccccccccccccccccc4444444444444444cccc
4444bbbbbbbbbbbbbbbc4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc333333ccc0000ccccccccc44444444444444444cccc
4444bbbbbbbbbbbbbbbb44cccccccdcccc00000cccccccaacaacccccccccccccccccccccccccccccccccc3b3333ccc00000ccccccc44444444444c444444cccc
44443bbbbbb33333bbbb444cccccccccc0f00000ccccccaaaaacccccccccccccaaaaaaccccccccccccccc333333cccffff5cccccc444444444444444cc44cccc
4444333bb33333333bbb4444ccccccccc0ffff00ccccccca9accccccccccccca998888acccccccccccccc333b33ccc1ff1fccccc4444444444444444cc44cccc
444433333333333333bb44444ccccccccff1ff10bcccccaaaaacccccccccccca988888acbcccccccbccccc3333ccccfffff1ccc444444444444444444444cccc
444433333333333333bb444444ccccccc0fffff0ccccccaa3aaccccccccccccaaaaaaaabcccccccbccccccc44cccccc11111cc4444444444444444c44444cccc
444433333333333333bb4444444cccccccf222cbcc3cccccbccccc3cc33cccca980088abcc3cc3cbcc3cccc44cccccf111fcc44444444444c44444444444cccc
444433333333333333bb44444444cccccc1cc1c33c3cccccbcccc33c3333ccca988888a33c3cc3c33c3ccc9999ccccc0cc0c444444444444444444444444cccc
44443333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbc444444444444444444444444cccc
44443333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb4c444444444444444444444ccbcc
cc4433333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33333bbbb4444cc4444444444444444cccccc
cc443333333333333333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb33333333bbb4444cc444444444444444ccccccc
44443333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333bb44444444444444444444cccccccc
44443333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333bb44c4444444444444444ccccccccc
44443333338888333333333333333333333333333333333333333333333333333333333333333333333333333333333333bb444444444444444444cccccccccc
44443333388888833333333333333333333333d33333333333333333333333333333333333333333333333333333333333bb44444444444444444ccccccccccc
4444ccccc878888ccccc44444444bb333333333333333333333333333333333333333bb333333333333333333333333333bb4444444444444444cccccccccccc
444cccccc888888cccccc4444444bbb33333388338833388883333883333388888833bb88833388338833888888333333bbb444444444444444ccccccccccccc
44ccccccc888888ccccccc444444bbb333333883388333888833338833333888888333888833388838833888888333333bbb44444444444444cccccccccccccc
4cccccccc888888cccccccc44444bbbb3333388338833883388333883333333883333883388338888883333883333333bbbb4444444444444ccccccccccccccc
cccccccccc8888cccccccccc4444bbbb3333388338833883388333883333333883333883388338888883333883333333bbbb444444444444cccccccccccccccc
cccccccccccc7cccccccccccc444bbb333333888888338888883338833333338833338888883388388833338833333333bbb44444444444ccccccccccccccccc
ccccccccccc7cccccccccccccc44bbb333333322223332233223332222233222222332233223322332233332233333333bbb4444444444cccccccccccccccccc
ccccccccccc7ccccccccccccccc4bb33333333322333322332233322222332222223322332233223322333322333333333bb444444444ccccccccccccccccccc
ccccccccccc7ccccccccccccccc4bb33333333333333333333333333333333333333333333333333333333333333333333bb44444444cccccccccccccccccccc
ccccccccccc7cccccccccccccc44bb33333333333333333333333333333333333333333333333333333333333333333333bb4444444ccccccccccccccccccccc
cccccccccccc7cccccccccccc444bb33333333333333333333333333333333333333333333333333333333333333333333bb444444cccccccccccccccccccccc
cccccccccccc7ccccccccccc4444bb33333333333333333333333333333333333333333333333333333333333333333333bb44444ccccccccccccccccccccccc
4cccccccccccccccccccccc44444bbb33333333bb333333bb333333bb333333bb333333bb333333bb333333bb33333333bbb4444cccccccccccccccccccccccc
44cccccccccccccccccccc444444bbbb33333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33333bbbb444ccccccccccccccccccccccccc
444cccccccccccccccccc4444444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb44cccccccccccccccccccccccccc
4444cccccccccccccccc44444444cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbc4ccccccccccccccccccccccccccc
44444cccccccccccccc444444444cccccccc66656665666566656665666566656665666566656665666566656665444444444ccccccccccccccccccccccccccc
444444cccccccccccc444444444ccccccccc67656765676567656765676567656765676567656765676567656765c444444444cccccccccccccccccccccccccc
4444444cccccccccc444444444cccccccccc677c677c677c677c677c677c677c677c677c677c677c677c677c677ccc444444444ccccccccccccccccccccccccc
44444444cccccccc444444444cccccccccccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccccc444444444ccccccccc499994ccccccccc
44444444bcccccc444444444ccccccccccccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7ccc7cccccc444444444ccccccccc5005cccccccccc
4444444444cccc444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc444444444ccccccccc55ccccccccccc
44444444444cc444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc444444444ccccccc5005cccccccccc
444444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc444444444ccccccc55ccccccccccc
44444444ccccccccb333333bb333333bcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444cbbbbbbbbbbbbbbccccc
c444444ccccccccc3bbbbbb33bbbbbb3ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444444bbbbbbbbbbbbbbbbcccc
cc4444cccccccccc3bbbbbb33bbbbbb3cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc444444bbbb333b3333bbbbcccc
ccc44ccccccccccc3bbbbbb33bbbbbb3ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444bbb3333333333bbbcccc
cccccccccccccccc3bbbbbb33bbbbbb3cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444bbb33333333333bbcccc
cccccccccccccccc3bbbbbb33bbbbbb3ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc444bbbb333b333333bbcccc
cccccccccccccccc3bbbbbb33bbbbbb3cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44bbbbbbbb333333bbcccc
ccccccccccccccccb333333bb333333bccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4cbbbbbbb333333bbcccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbb3333bbcccc
cc00cc00c00cc000c000cc00c0cccc00ccccccccc000c000c000cc00c0c0ccccc0c0c000c0c0cc00ccccc000cc00ccccc000cc00c0c0c000ccccbbb333bbcccc
c0ccc0c0c0c0cc0cc0c0c0c0c0ccc0cccc0cccccc0c0c0c0c0c0b0c0c0c0ccccc0c0c0ccc0c0c0cccccccc0cc0c0ccccc000c0c0c0c0c0ccccccbbb333bbcccc
c0ccc0c0c0c0cc0cc00cc0c0c0ccc000ccccccccc000c00cc00cc0c0c0c0ccccc00cc00cc000c000cccccc0cc0c0ccccc0c0c0c0c0c0c00cccccbb333bbbcccc
c0ccc0c0c0c0cc0cc0c0c0c0c0ccccc0cc0cccccc0c0c0c0c0c0c0c0c000ccccc0c0c0ccccc0ccc0cccccc0cc0c0ccccc0c0c0c0c000c0ccccccbb333bbbcccc
cc00c00cc0c0cc0cc0c0c00cc000c00cccccccccc0c0c0c0c0c0c00cc000ccccc0c0c000c000c00ccccccc0cc00cccccc0c0c00ccc0cc000ccccbbb33bbbcccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbb33bbbcccc
ccccc000ccccc000cc00ccccc000c0c0c000c000ccccccccc0c0ccccc000cc00ccccc000cc00c0c0c000c000ccccc00cc000cc00c0c0ccccccccbb3333bbcccc
ccccccc0cccccc0cc0c0cccccc0cc0c0c000c0c0ccccccccc0c0cccccc0cc0c0ccccc0c0c0c0c0c0c0ccc0c0ccccc0c0c0c0c0ccc0c0ccccccccbb3333bbcccc
cccccc0ccccccc0cc0c0cccccc0cc0c0c0c0c000cccccccccc0ccccccc0cc0c0ccccc000c0c0c0c0c00cc00cccccc0c0c000c000c000ccccccccbbb333bbcccc
ccccc0cccccccc0cc0c0cccccc0cc0c0c0c0c0cccc0cccccc0c0cccccc0cc0c0ccccc0ccc0c0c000c0ccc0c0ccccc0c0c0c0ccc0c0c0bbccccccbbb333bbcccc
ccccc000cccccc0cc00cccccc00ccc00c0c0c0ccc0ccccccc0c0cccccc0cc00cccccc0ccc00cc000c000c0c0ccccc000c0c0c00cc0c0bbccccccbb333bbbcccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbb333bbbcccc
cccccc00c000ccccc0c0cc00c000ccccc000cccccc00c000c000c000c000c000c00ccc0cccccccccccccccccccccccccccccccccccccccccccccbbb33bbbcccc
ccccc0c0c0c0ccccc0c0c0ccc0ccccccc0c0ccccc0ccc0c0c000c0ccc0c0c0c0c0c0cc0cccccccccccccccccccccccccccccccccccccccccccccbbb33bbbcccc
ccccc0c0c00cccccc0c0c000c00cccccc000ccccc0ccc000c0c0c00cc000c000c0c0cc0cccccccccccccccccccccccccccccccccccccccccccccbb3333bb777c
ccccc0c0c0c0ccccc0c0ccc0c0ccccccc0c0ccccc0c0c0c0c0c0c0ccc0ccc0c0c0c0cccccccccccccccccccccccccccccccccccccccccccccc77bb3333bb7777
ccccc00cc0c0cccccc00c00cc000ccccc0c0ccccc000c0c0c0c0c000c0ccc0c0c000cc0cccccccccccccccccccccccccccccccccccccccccc776bbb333bb6777
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc767bbb333bb6667
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc499994cccccbb333bbbcccc
ccccccccccccccccccccccccccc44ccccccccccccccccccccccccccccccccccccccccccccbcccccccccccccccccccccccccccccccc5005ccccccbb333bbbcccc
cccccccccccccccccccccccccc4444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc55cccccccbbb33bbbcccc
ccccccccccccccccccccccccc444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5005ccccccbbb33bbbcccc
cccccccccccccccccccccccc44444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc55cccccccbb3333bbcccc
4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444cbbbbbbbbbbbbbbb333333bbcccc
44444c444444444444444444444444444444444444444444444444444444444444444c444444444444444444444444444444bbbbbbbbbbbbbbbb333333bbcccc
44444444cc44444444444444444444444444444444444444444444444444444444444444cc44444444444444444444444444bbbb333bbbbbbbbb333333bbcccc
44444444cc44444444444444444444444444444444444444444444444444444444444444cc44444444444444444444444444bbb33333b3bbbb33333333bbcccc
4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbb3333333bbbb3b33333bbbcccc
444444c444444444444444444444444444444444444444444444444444444444444444c44444444444444444444444444444bbbb333bbbbbbbbb3333bbbbcccc
4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444bbbbbbbbbbbbbbbbbbbbbbbbcccc
4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444cbbbbbbbbbbbbbbbbbbbbbbccccc
cccccccccccccccccccccccccccccccccccccccccccccccc44444444cccccccccccccccccccccccccccccccccccccccccccc444444444444444444444444cccc
ccccccccccccccccccccccccccccccccccccccccccccccccc444444cccccccccccccccccccccccccccccccccccccccccccccc4444444444444444444444ccccc
cccccccccccccccccccccccccccccccccccccccccccccccccc4444cccccccccccccccccccccccccccccccccccccccccccccccc44444444444444444444cccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccc44cccccccccccccccccccccccccccccccccccccccccccccccccc444444444444444444ccccccc
777c7c7c777c77cc7c7cc77ccccc777cc77ccccccccc77cc777c77cc777c777c7ccccccc7ccc777c77ccc77cc77c777c77cccccc4444444444444444cccccccc
c7cc7c7c7c7c7c7c7c7c7cccccccc7cc7c7cc7cccccc7c7c7c7c7c7cc7cc7ccc7ccccccc7cccc7cc7c7c7ccc7ccc7ccc7c7cccccc44444444444444ccccccccc
c7cc777c777c7c7c77cc777cccccc7cc7c7ccccccccc7c7c777c7c7cc7cc77cc7ccccccc7cccc7cc7c7c777c777c77cc7c7ccccccc444444444444cccccccccc
c7cc7c7c7c7c7c7c7c7ccc7cccccc7cc7c7cc7cccccc7c7c7c7c7c7cc7cc7ccc7ccccccc7cccc7cc7c7ccc7ccc7c7ccc7c7cccccccc4444444444ccccccccccc
c7cc7c7c7c7c7c7c7c7c77ccccccc7cc77cccccccccc777c7c7c7c7c777c777c777ccccc777c777c7c7c77cc77cc777c7c7ccccccccc44444444cccccccccccc
cccccccccccccccccccccccccccccbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4c444444cccccccccccc
777c777c777c777ccccc777c7c7cc77c777cc77cc77c77cccccc77cccccc77ccc77c777c7ccccccc777c777c777c777c7c7ccccccccc4444cc44cccccccccccc
777c7c7cc7ccc7ccccccc7cc7c7c7c7c7c7c7ccc7c7c7c7ccccc77cccccc7c7c7c7c7ccc7ccccccc7c7c7ccc7c7c7c7c7c7ccccccccc4444cc44cccccccccccc
7c7c777cc7ccc7ccccccc7cc777c7c7c77cc777c7c7c7c7ccccc77cccccc7c7c7c7c77cc7ccccccc77cc77cc77cc77cc777ccccccccc44444444cccccccccccc
7c7c7c7cc7ccc7ccccccc7cc7c7c7c7c7c7ccc7c7c7c7c7ccccc7c7ccccc7c7c7c7c7ccc7ccccccc7c7c7ccc7c7c7c7ccc7ccccccccc44c44444cccccccccccc
7c7c7c7cc7ccc7ccccccc7cc7c7c77cc7c7c77cc77cc7c7ccccc777ccccc7c7c77cc777c777ccccc777c777c7c7c7c7c777ccccccccc44444444cccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444cccccccccccc

__gff__
0000000000000000000000000000000002020000000200000000020202000000030303030303030302020202020000000303030303030303020202020202020200001302020210000302020202020202000000020200020202020000020202020202020202020202020202020202020202020202020202010102020202020200
0000000000000000000200000202030000000000000002000002020000000000010000000000000002000202000000030000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
252525252525267374242525252525252525252526303132323232323373742732323233737424253232323232323232252525252525252526737431323232252525252526303132323232323273742426737400242525323232323232323225afafafafafafafafafafafafaf7374af25252525330000737400003125252525
32323232323233282831323232323232252525482637282900004e4f00000030282810282828243300000000000000002525323232324825268900151c15682400000000000000000000000000000024264041002432330000000040410000240000003a294d002a2828397eaf2828af25252533000000000000000031252525
002a3828393a2875282900007b28282425252525331029003f212317171734262a282828292a3000000000000000000032333828282831323399687b7c282824000000000000000000000000000000242650510030000040410000505100082401003a295c5d00002a282839af292aaf25253300000000000000000000312525
00002a2838292a382839000068387b2425254826382900002148263829000037002a382916003739643d143d3d0000002828292a10283828212222232b2a28240000000000000014000000000000002426000000300000505100000040412148afafafafafafafafafafaf28af393aaf25330000000000001400000000003125
0000002a10393a282828670028390024254825262900002148323329000000212c002a2810282817222222223600000038290000002a2810243232332b3a28240000000000171717171700003f000024267500003740410000000000505124253a2900000000000000002a28282828af26000000160000007700001600940024
00000000282828292a2810282838393132322526000021253310393f27003a243c72002a28382900222222000000000029010000000038283027283828282924720000000000000000000040410000242620404100505100270000000034332529afafafafafafafafafafafafafafaf33000000000000000000000000000031
3d143e38282829123d28282900002a2829923133002148332828212126391024222216002a2900002222003a390016004242424242422817303728282828272423003f0000003a390000005051121224263f5051873f404130343600004041240000af000063606060606060606047af00000000000000000000000000000000
2122232838290034362839000000002a00004041003133002a214824262a2824222200000000000000003a102a390000262810282828292a242338282828242444432300083a2838390000000034353325222222223650513040414041505124af00af00006100afafafafafafafafaf0000000c000000000000000c00000000
31323329000000002a2828393d0896973f145051754e4f3f21252524266728242500000000000000003a0800002a39002628282838290000242600002a3824244444444323292a2828390000008a0043253232323334360030505150512122480000af3900610000000000000000000000000000000000000000000000000000
2028290000000000002a382821222223222222222222232123212324262a682400000000160000003a280000003829392638290000000011242600143a102424444444444443232828283900000000432640410000004041304041003432322500afafaf3961afafafafafafafafaf00000b00000b0000000b00000000000b00
332900000000002c00002a343322252632323232323233242631332426002a24000000000000003a281111110029162a262900111111112125261717382824244444444444444443231028390000004326505140410050513050510000404124003aafafaf70606060606062007eaf0000000000000000000000160800000000
290000000000723c0000002a212525267b7d68677b7c7d3133382931330000240000000000003a38282122223828392826003b424242424232333a28282824244444444444444444442223103900004326000050510000003034364000505131af28afafaf00afafafaf00610000af3a00001600000000000000002700000000
0000000000002123000000002425252600004e4f000000284e4f00000000002400000000003a102a29002222382838292600001b1b1b1b1b003a28102900243132323232323232323232332828395943263f14404100000037404150510100592829af004660606060606071afafaf2800000000000c000000000c3000000000
013d59000000242600000000242525263f010000000067383900000008000024000064013a1039127b6722221028290026000000000000003a28382900002425282828382810282828102838282123432522235051000021235051212340412129afaf00000000000000003a7b7c7c7d00000000000000000000003000000000
21222300000024261111111131252525222223390000004e7c4f3f3f5900002400002222233829273828222228297559330800000046003a38282839003f242529012a2828282838282828282824264325254822233f202426003f31335051240000000059af00140000af29000000000001000b000000000b000030000b0000
242526390068242522222222222225252548253817171717171721222311112400002222232828302838242229003436424242424242424242424228392125252122234343484343484343484824264325252525252222222200222222222225afafafafafafafafafafafafaf00afaf00270000000000000000003000000000
0000000000000073740000000000000025323232323232323232323232323225000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000002600000000000000000000000000002400000000009a9a9a9a9a9a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005500000000005500000000005526000000000000000000000000000024000000009a9a9a9a9a9a9a9a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000260000000056560056560000000000240000009a9a9a9a9a9a9a9a9a9a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000026000000564b5856574c5600000000240000009a9a9a9a9a9a9a9a9a9a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005500000000550000005500000026000000561a49084b6656000000002400009a9a9a9a9a9a9a9a9a9a9a9a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003a2828282600000000564a45495600000000002400009a9a9a9a9a9a9a9a9a9a9a9a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010100000000000000000000000001000000000000000000000
00550000550000550000553a29001400260000000000565556000000000000240000009a9a9a9a9a9a9a9a9a9a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000002a39252525260000000000005600000000000000240000009a9a9a9a9a9a9a9a9a9a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000002a282828260001000000000000000000bf00a024000000009a9a9a9a9a9a9a9a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000002522222222222222222222222222222500000000009a9a9a9a9a9a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55000055000055000055000055003a7b252525252525252525252525252525250000000000009a9a9a9a0000000000000000000000000000000000000000000000000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000002808252525252525252525252525252525250000000000008c00008d0000000000000000000000000000000000000000000000000000000000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c7c7c7d390000000000000000002800252525252525252525252525252525250000000000006f01595f0000000000000000000000000000000000000000000000000000000000000000000010001000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01005900281000550000550000552825252525252525252525252525252525250000000000006f8e8e5f0000000000000000000000000000000000000000000000000039390000000000000010101010101000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25252568290000000000000000000000252525252525252525252525252525250000000000000000000000000000000000000000000000000000000028292a3828390000103900000000001010100010001000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0002000036370234702f3701d4702a37017470273701347023370114701e3700e4701a3600c46016350084401233005420196001960019600196003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
0002000011070130701a0702407000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d07010070160702207000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000642008420094200b420224402a4503c6503b6503b6503965036650326502d6502865024640216401d6401a64016630116300e6300b62007620056100361010600106000060000600006000060000600
000400000f0701e070120702207017070260701b0602c060210503105027040360402b0303a030300203e02035010000000000000000000000000000000000000000000000000000000000000000000000000000
000300000977009770097600975008740077300672005715357003470034700347003470034700347003570035700357003570035700347003470034700337003370033700337000070000700007000070000700
00030000241700e1702d1701617034170201603b160281503f1402f120281101d1101011003110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00020000101101211014110161101a120201202613032140321403410000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000070700a0700e0701007016070220702f0702f0602c0602c0502f0502f0402c0402c0302f0202f0102c000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000005110071303f6403f6403f6303f6203f6103f6153f6003f6003f600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000200177500605017750170523655017750160500605017750060501705076052365500605017750060501775017050177500605236550177501605006050177500605256050160523655256050177523655
002000001d0401d0401d0301d020180401804018030180201b0301b02022040220461f0351f03016040160401d0401d0401d002130611803018030180021f061240502202016040130201d0401b0221804018040
00100000070700706007050110000707007060030510f0700a0700a0600a0500a0000a0700a0600505005040030700306003000030500c0700c0601105016070160600f071050500a07005050030510a0700a060
000400000c5501c5601057023570195702c5702157037570285703b5702c5703e560315503e540315303e530315203f520315203f520315103f510315103f510315103f510315103f50000500005000050000500
000400002f7402b760267701d7701577015770197701c750177300170015700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00030000096450e655066550a6550d6550565511655076550c655046550965511645086350d615006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
011000001f37518375273752730027300243001d300263002a3001c30019300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
011000002953429554295741d540225702256018570185701856018500185701856000500165701657216562275142753427554275741f5701f5601f500135201b55135530305602454029570295602257022560
011000200a0700a0500f0710f0500a0600a040110701105007000070001107011050070600704000000000000a0700a0500f0700f0500a0600a0401307113050000000000013070130500f0700f0500000000000
002000002204022030220201b0112404024030270501f0202b0402202027050220202904029030290201601022040220302b0401b030240422403227040180301d0401d0301f0521f0421f0301d0211d0401d030
0108002001770017753f6253b6003c6003b6003f6253160023650236553c600000003f62500000017750170001770017753f6003f6003f625000003f62500000236502365500000000003f625000000000000000
002000200a1400a1300a1201113011120111101b1401b13018152181421813213140131401313013120131100f1400f1300f12011130111201111016142161321315013140131301312013110131101311013100
001000202e750377502e730377302e720377202e71037710227502b750227302b7301d750247501d730247301f750277501f730277301f7202772029750307502973030730297203072029710307102971030710
000600001877035770357703576035750357403573035720357103570000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001800202945035710294403571029430377102942037710224503571022440274503c710274403c710274202e450357102e440357102e430377102e420377102e410244402b45035710294503c710294403c710
0018002005570055700557005570055700000005570075700a5700a5700a570000000a570000000a5700357005570055700557000000055700557005570000000a570075700c5700c5700f570000000a57007570
010c00103b6352e6003b625000003b61500000000003360033640336303362033610336103f6003f6150000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c002024450307102b4503071024440307002b44037700244203a7102b4203a71024410357102b410357101d45033710244503c7101d4403771024440337001d42035700244202e7101d4102e7102441037700
011800200c5700c5600c550000001157011560115500c5000c5700c5600f5710f56013570135600a5700a5600c5700c5600c550000000f5700f5600f550000000a5700a5600a5500f50011570115600a5700a560
001800200c5700c5600c55000000115701156011550000000c5700c5600f5710f56013570135600f5700f5600c5700c5700c5600c5600c5500c5300c5000c5000c5000a5000a5000a50011500115000a5000a500
000c0020247712477024762247523a0103a010187523a0103501035010187523501018750370003700037000227712277222762227001f7711f7721f762247002277122772227620070027771277722776200700
000c0020247712477024762247523a0103a010187503a01035010350101875035010187501870018700007001f7711f7701f7621f7521870000700187511b7002277122770227622275237012370123701237002
000c0000247712477024772247722476224752247422473224722247120070000700007000070000700007002e0002e0002e0102e010350103501033011330102b0102b0102b0102b00030010300123001230012
000c00200c3320c3320c3220c3220c3120c3120c3120c3020c3320c3320c3220c3220c3120c3120c3120c30207332073320732207322073120731207312073020a3320a3320a3220a3220a3120a3120a3120a302
000c00000c3300c3300c3200c3200c3100c3100c3103a0000c3300c3300c3200c3200c3100c3100c3103f0000a3300a3201333013320073300732007310113000a3300a3200a3103c0000f3300f3200f3103a000
000400001b32537605000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000c00000c3300c3300c3300c3200c3200c3200c3100c3100c3100c31000000000000000000000000000000000000000000000000000000000000000000000000a3000a3000a3000a3000a3310a3300332103320
001000000c3500c3400c3300c3200f3500f3400f3300f320183501834013350133401835013350163401d3600a370093700a360093600a350093400a330093200a30009300133001330016300163001d3001d300
000c0000242752b27530275242652b26530265242552b25530255242452b24530245242352b23530235242252b22530225242152b21530215242052b20530205242052b205302053a2052e205002050020500205
001000102f65501075010753f615010753f6152f65501075010753f615010753f6152f6553f615010753f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
0010000016270162701f2711f2701f2701f270182711827013271132701d2711d270162711627016270162701b2711b2701b2701b270000001b200000001b2000000000000000000000000000000000000000000
00080020245753057524545305451b565275651f5752b5751f5452b5451f5352b5351f5252b5251f5152b5151b575275751b545275451b535275351d575295751d545295451d535295351f5752b5751f5452b545
002000200c2650c2650c2550c2550c2450c2450c2350a2310f2650f2650f2550f2550f2450f2450f2351623113265132651325513255132451324513235132351322507240162701326113250132420f2600f250
00100000072750726507255072450f2650f2550c2750c2650c2550c2450c2350c22507275072650725507245072750726507255072450c2650c25511275112651125511245132651325516275162651625516245
000800201f5702b5701f5402b54018550245501b570275701b540275401857024570185402454018530245301b570275701b540275401d530295301d520295201f5702b5701f5402b5401f5302b5301b55027550
00100020112751126511255112451326513255182751826518255182451d2651d2550f2651824513275162550f2750f2650f2550f2451126511255162751626516255162451b2651b255222751f2451826513235
00100010010752f655010753f6152f6553f615010753f615010753f6152f655010752f6553f615010753f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
001000100107501075010753f6152f6553f6153f61501075010753f615010753f6152f6553f6152f6553f61500005000050000500005000050000500005000050000500005000050000500005000050000500005
002000002904029040290302b031290242b021290142b01133044300412e0442e03030044300302b0412b0302e0442e0402e030300312e024300212e024300212b0442e0412b0342e0212b0442b0402903129022
000800202451524515245252452524535245352454524545245552455524565245652457500505245750050524565005052456500505245550050524555005052454500505245350050524525005052451500505
000800201f5151f5151f5251f5251f5351f5351f5451f5451f5551f5551f5651f5651f575000051f575000051f565000051f565000051f555000051f555000051f545000051f535000051f525000051f51500005
000500000373005731077410c741137511b7612437030371275702e5712437030371275702e5712436030361275602e5612435030351275502e5512434030341275402e5412433030331275202e5212431030311
002000200c2750c2650c2550c2450c2350a2650a2550a2450f2750f2650f2550f2450f2350c2650c2550c2450c2750c2650c2550c2450c2350a2650a2550a2450f2750f2650f2550f2450f235112651125511245
002000001327513265132551324513235112651125511245162751626516255162451623513265132551324513275132651325513245132350f2650f2550f2450c25011231162650f24516272162520c2700c255
000300001f3302b33022530295301f3202b32022520295201f3102b31022510295101f3002b300225002950000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00002935500300293453037030360303551330524300243050030013305243002430500300003002430024305003000030000300003000030000300003000030000300003000030000300003000030000300
001000003c5753c5453c5353c5253c5153c51537555375453a5753a5553a5453a5353a5253a5253a5153a51535575355553554535545355353553535525355253551535515335753355533545335353352533515
00100000355753555535545355353552535525355153551537555375353357533555335453353533525335253a5753a5453a5353a5253a5153a51533575335553354533545335353353533525335253351533515
001000200c0600c0300c0500c0300c0500c0300c0100c0000c0600c0300c0500c0300c0500c0300c0100f0001106011030110501103011010110000a0600a0300a0500a0300a0500a0300a0500a0300a01000000
001000000506005030050500503005010050000706007030070500703007010000000f0600f0300f010000000c0600c0300c0500c0300c0500c0300c0500c0300c0500c0300c010000000c0600c0300c0100c000
0010000003625246150060503615246251b61522625036150060503615116253361522625006051d6250a61537625186152e6251d615006053761537625186152e6251d61511625036150060503615246251d615
00100020326103261032610326103161031610306102e6102a610256101b610136100f6100d6100c6100c6100c6100c6100c6100f610146101d610246102a6102e61030610316103361033610346103461034610
00400000302453020530235332252b23530205302253020530205302253020530205302153020530205302152b2452b2052b23527225292352b2052b2252b2052b2052b2252b2052b2052b2152b2052b2052b215
000400001d6101f620246303074030750307503074030740307303072030710307103070030700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 150a5644
00 0a160c44
00 0a160c44
00 0a0b0c44
00 14131244
00 0a160c44
00 0a160c44
02 0a111244
00 41424344
00 41424344
01 18191a44
00 18191a44
00 1c1b1a44
00 1d1b1a44
00 1f211a44
00 1f1a2144
00 1e1a2244
02 201a2444
00 41424344
00 41424344
01 2a272944
00 2a272944
00 2f2b2944
00 2f2b2c44
00 2f2b2944
00 2f2b2c44
00 2e2d3044
00 34312744
02 35322744
00 41424344
01 3d7e4344
00 3d7e4344
00 3d4a4344
02 3d3e4344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 383a3c44
02 393b3c44

