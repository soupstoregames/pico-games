pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
state_stack = {}
frame=0
last_time=t()

function _init()
	cartdata("soupstoregames_for_1_0")
	load_level_progress()
	set_palette()
	add(state_stack, state_menu())	
end

function _update()
-- update frame index
	if t()-last_time > 0.03 then
		frame=frame+1
		last_time=t()
	end
		
	state_stack[#state_stack]:update()
end

function _draw()
	cls()

	for i=1,#state_stack do
		state_stack[i]:draw(i==#state_stack)
	end
end

function set_palette()
	_pal={0,5,6,7,129,1,140,12,136,8,137,9,130,141,11,3}
	for i,c in pairs(_pal) do
		pal(i-1,c,1)
	end
end

function reset_frame()
	frame=0
	last_time=t()
end

function load_level_progress()
	for i=1,#levels do
		levels[i]=dget(i)
	end
	if levels[1] == lvl_locked then
		levels[1] = lvl_ready
	end
	level=dget(0)
	if level == 0 then
		level=1
	end
end

function vector(x,y)
	local v={x=x,y=y}

	function v:equal(v2)
		return self.x==v2.x and self.y==v2.y
	end
	
	function v:add(v2)
		return vector(self.x+v2.x,self.y+v2.y)
	end
	
	function v:sub(v2)
		return vector(self.x-v2.x,self.y-v2.y)
	end
	
	function v:mul(s)
		return vector(self.x*s,self.y*s)
	end
	
	function v:mag()
		x,y=abs(self.x),abs(self.y)
		return sqrt(x*x+y*y)
	end
	
	function v:distance(v2)
		x,y=abs(self.x-v2.x),abs(self.y-v2.y)
		return sqrt(x*x+y*y)
	end

	return v
end

dirs={
	vector(-1,0),
	vector(1,0),
	vector(0,-1),
	vector(0,1)
}
-->8
-- menu state

level=1
lvl_locked=0
lvl_ready=1
lvl_complete=2

levels={
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
	lvl_ready,
}

function state_menu()
	local state = {}
		
	function state:update()
		if btnp(⬅️) then
			if (level-1)%8>0 then
				level=level-1
				dset(0,level)
			end 
		end
		
		if btnp(➡️) then
			if (level-1)%8<7 then
				level=level+1
				dset(0,level)
			end 
		end
		
		if btnp(⬆️) then
			if flr((level-1)/8)>0 then
				level=level-8
				dset(0,level)
			end 
		end
				
		if btnp(⬇️) then
			if flr((level-1)/8)<flr(#levels/8)-1 then
				level=level+8
				dset(0,level)
			end
		end
		
		if btnp(🅾️) then
			if levels[level] != lvl_locked then
				add(state_stack, state_game(level-1))
			end
		end
	end
	
	function state:draw()
		cls(4)
		
		print("for",50,24,14)
		print("{ }",64,24,9)
		print("by",29,36,8)
		print("soupstoregames",41,36,15)
		 
		for i=1,#levels do
			level_button(i,levels[i],level==i)
		end
		
		if levels[level] != lvl_locked then
			print("press 🅾️ to play",30,100,6)
		else
			print("locked",51,100,9)
		end
	end
	
	return state
end

function level_button(num,mode,selected)
	local x=((num-1)%8)*12+16
	local y=flr((num-1)/8)*12+50
	
	local bg=8
	local fg=10
	if mode == lvl_ready then
		bg=6
		fg=7
	elseif mode == lvl_complete then
		bg=15
		fg=14
	end
	rectfill(x,y,x+8,y+8,bg)
	print(pad(num),x+1,y+2,fg)
	if selected then
		rect(x-1,y-1,x+9,y+9,7)
	end
end

function pad(num)
	local str=tostr(num)
	if #str == 1 then
		return "0"..str
	end
	return str
end
-->8
-- game state
map_size=15
home_spr=17
player_spr=1
door_spr=32
teleporter_spr=18
pusher_spr=33

info_text={
	{22,13,7,{
		" when you move, the",
		"program runs the next",
		"     instruction",
		"",
		"",
		"  these activate in",
		" order and run the",
		"   command block next",
		" to the green light",
	}},
	{24,38,11,{
		"this block loops  ",
		"   execution back to  ",
		"       position zero ",
	}},
	{24,86,11,{
		"you escape the level",
		"   when this block  ",
		"     is executed    ",
	}},
	{71,42,6,{
		"this     ",
		"   block",
		"will move",
		" you back",
		"to the",
		"home tile",
	}},
	{24,42,9,{
		"dont let ",
		"the",
		"program",
		"run past",
		"the last",
		"position!",
	}},
	nil,
	nil,
	nil,
	{24,38,11,{
		"  this block toggles",
		"the orange gates... ",
		" they look dangerous! ",
	}},
}

function state_game()
	sfx(35,-2)
			
	local state = {
		addr=1,
		steps=0,
		show_doors=true,
		addresses={},
		blocks={},
		memmap={},
		doors={},
		
		teleporters={},
		teleporters_active_frame=0,
		teleporters_active=false,
		
		pushers={},
		lasers={},
		fire_lasers=false,
		
		player_spawn=vector(0,0),
		player=nil,
		explosions={},
	}
	
	reset_frame()
	
	for y=0,map_size-1 do
		for x=0,map_size-1 do
			local s=level_get(x,y)
			-- scan for player spawn
			if s==home_spr then
			 state.player_spawn=vector(x,y)
				state.player=player(vector(x,y))
				add(state.memmap,s)
			-- scan for teleporterss
			elseif s==teleporter_spr then
			 add(state.teleporters,vector(x,y))
				add(state.memmap,s)
			-- scan for addr tile
			elseif s>=64 and s<=127 then
				s=s-64
				state.addresses[s%16+1] = address(s%16,dirs[flr(s/16)+1],s+64,vector(x,y))
				add(state.memmap,0)
			elseif s>=38 and s<=41 then
				add(state.lasers,laser(vector(x,y),s-37))
				add(state.memmap,0)
			-- scan for pusher block
			elseif s==pusher_spr then
				add(state.pushers,pusher(vector(x,y)))
				add(state.memmap,0)
			-- scan for goal block
			elseif s==door_spr then
				add(state.doors,vector(x,y))
				add(state.memmap,0)
			elseif s==goal_spr then
				add(state.blocks,goal_block(vector(x,y))) 
				add(state.memmap,0)
			-- scan for loop block
			elseif s==loop_spr then
			 add(state.blocks,loop_block(vector(x,y)))
				add(state.memmap,0)
			-- scan for reset block
			elseif s==reset_spr then
			 add(state.blocks,reset_block(vector(x,y)))
				add(state.memmap,0)
			-- scan for door controller block
			elseif s==doorc_spr then
			 add(state.blocks,door_block(vector(x,y)))
				add(state.memmap,0)
			-- scan for teleport block
			elseif s==teleport_spr then
			 add(state.blocks,teleport_block(vector(x,y)))
				add(state.memmap,0)
			-- scan for pusher block
			elseif s==pusherc_spr then
			 add(state.blocks,pusher_block(vector(x,y)))
				add(state.memmap,0)
			-- scan for laser block
			elseif s==laserc_spr then
			 add(state.blocks,laser_block(vector(x,y)))
				add(state.memmap,0)
			else
				add(state.memmap,s)
			end
		end
	end

	function state:update()
		if self.fire_lasers then
			for l in all(self.lasers) do
				l:fire(state)
			end
			self.fire_lasers=false
		end
		
		local laser_deleted=false
		repeat
			for l in all(self.lasers) do
				if l.dead then
					del(state.lasers,l)
					laser_deleted=true
					break
				end
			end
			laser_deleted=false
		until not laser_deleted
		
		for l in all(self.lasers) do
			l:update(self)
		end
		
		if #self.lasers==0 then
			sfx(35,-2)
		end
	
		for e in all(self.explosions) do
			e:update()
			if #e.p == 0 then
				del(self.explosions,e)
			end
		end
		
		if self.teleporters_active then
			if frame - self.teleporters_active_frame > 5 then
				self.teleporters_active=false
				self.teleporters_active_frame=0
			end
		end
	
		if btnp(🅾️) then
			del(state_stack,state_stack[#state_stack])
			add(state_stack, state_game())
		end
		
		if btnp(❎) then
			del(state_stack,state_stack[#state_stack])
		end
		
		local wait_for_pushers=false
		for p in all(self.pushers) do
			p:update(self)
			if p.animating then
				wait_for_pushers=true
			end
		end
		if wait_for_pushers then
			return
		end
		
		if self.player.dead then
			if #self.explosions==0 then
				add(state_stack,state_lose())
			end
			return
		end
	
		if self.player.direction != nil then
			if self.player:move_towards() then
				
				local exit_early = state.addresses[state.addr]:execute(state)
				if exit_early then
					return
				end
				state.addr=state.addr+1
				
				-- if we are out of steps
				-- then we lose!
				if state.addr == #state.addresses+1 then
					add(state_stack,state_lose())
					return
				end
			end
			return
		end
		
		-- move player
		self:poll_movement()
	end
	
	function state:poll_movement()
		local num_pressed=0
		for i=0,3 do
			if btn(i) then
				num_pressed=num_pressed+1
			end
		end
		
		if num_pressed != 1 then
			return
		end
		
		for i=0,3 do
			if btn(i) then
				local direction=dirs[i+1]
				local target=self.player.pos:add(direction)
				-- check if there is a wall
				if not self:is_blocked(target) then 
					-- check if there a block to push 
					local b=get_block(state.blocks,target)
					-- we have a block to push
					if b != nil then
						local block_target=target:add(direction)
						-- if there is no wall or
						-- block then we can push it
						if not self:is_blocked(block_target) and get_block(state.blocks,block_target) == nil then
							// block pushing
							self.player:attach(b)
							sfx(20)
							self.player:move(dirs[i+1])
							sfx(10)
							self.steps=self.steps+1
						end
					else
						self.player:move(dirs[i+1])
						sfx(10)
						self.steps=self.steps+1
					end
				end
			end
		end
	end
	
	function state:draw(top)
		cls()
		
		-- draw level
		for y=0,map_size-1 do
			for x=0,map_size-1 do
				local idx=y*map_size+x+1
				spr(self.memmap[idx],x*8+4,y*8+4)
			end
		end
	
		-- draw addrs
		for a in all(self.addresses) do
			if a.num == state.addr-1 then
				pal(10,14)
				draw_sprite(a.sprite,a.pos,vector(0,0))
				pal()
				set_palette()
			else
				draw_sprite(a.sprite,a.pos,vector(0,0))
			end
		end
		
		-- draw teleporters if active
		if self.teleporters_active then
			for t in all(self.teleporters) do
				draw_sprite(teleporter_spr+1,t,vector(0,0))
			end
		end
		
		
		-- draw lasers
		for l in all(self.lasers) do
			l:draw()
		end
		
		
		-- draw pushers
		for p in all(self.pushers) do
			p:draw()
		end
		
		-- draw blocks
		for b in all(self.blocks) do
			draw_sprite(b.sprite,b.pos,b.mpos)
		end
				
		-- draw player
		if not self.player.dead then
			self.player:draw()
		end
		
		-- draw doors
		if self.show_doors then
			for d in all(self.doors) do
				draw_sprite(door_spr,d,vector(0,0))
			end
		end
		
		for e in all(self.explosions) do
			e:draw()
		end
		
		if info_text[level] != nil then
			local text=info_text[level]
				for i=1,#text[4] do
					print(text[4][i],text[1],text[2]+(i-1)*7,text[3])
				end
		end
		
		if top then
			rectfill(4,116,43,124,0)
			print("🅾️ restart",4,118,2)
			
			rectfill(84,116,124,124,0)
			print("❎ abandon",85,118,2)
		end
		
		draw_borders()
	end
	
	function state:is_blocked(pos)
		if pos.x < 0 or pos.x > 14 then
			return true,nil
		end
		
		if pos.y < 0 or pos.y > 14 then
			return true,nil
		end
		
		if state.memmap[pos.y*15+pos.x+1] == 16 then
			return true,0
		end
		
		if self.show_doors then
			for d in all(self.doors) do
				if d:equal(pos) then
					return true,1
				end
			end
		end
		
		for p in all(self.pushers) do
			if p.pos:equal(pos) then
				return true,2
			end
			
			if p.extended and not p.animating then
				for i=1,4 do
					if p.pos:equal(pos:add(dirs[i])) then
						for a in all(p.arms) do
							if p.pos:add(a.direction):equal(pos) then
								return true,3
							end
						end
					end
				end
			end
		end
		
		for l in all(self.lasers) do
			if l.pos:equal(pos) then
				return true,4
			end
		end
		
		return false
	end

	function state:toggle_doors()
		local destroyed = false
		state.show_doors= not state.show_doors
		if state.show_doors then
			for d in all(self.doors) do
				for b in all(self.blocks) do
					if b.pos:equal(d) then
						del(self.blocks, b)
						add(self.explosions,explosion(vector(b.pos.x*8+8,b.pos.y*8+8),{1,2,5,6,7}))
						destroyed=true
					end
				end
				
				if self.player.pos:equal(d) then
					self.player.dead=true
					add(self.explosions,explosion(vector(self.player.pos.x*8+8,self.player.pos.y*8+8),{4,5,6,14,15}))
					destroyed=true
				end
			end
		end
		if destroyed then
			sfx(0,1)
		end
	end
	
	function state:remove_door_at(pos)
		for d in all(state.doors) do
			if pos:equal(d) then
				del(state.doors,d)
				return
			end
		end
	end
	
	
	function state:remove_pusher_at(pos)
		for p in all(state.pushers) do
			if pos:equal(p.pos) then
				del(state.pushers,p)
				return
			end
		end
	end
	
	function state:remove_laser_at(pos)
		for l in all(state.lasers) do
			if pos:equal(l.pos) then
				l.dead=true
				return
			end
		end
	end
	
	function state:remove_block_at(pos)
		for b in all(state.blocks) do
			if pos:equal(b.pos) then
				del(state.blocks,b)
				return
			end
		end
	end
	
	return state
end

function level_get(x,y)
	x=x+(level-1)%8*16
	y=y+flr((level-1)/8)*16
	return mget(x,y)
end

function level_set(x,y,sprite)
	x=x+(level-1)%8*16
	y=y+flr((level-1)/8)*16
	return mset(x,y,sprite)
end

function draw_level()
	local x=(level-1)%8*16
	local y=flr((level-1)/8)*16
	map(x,y,4,4)
end

function draw_borders()
	line(0,0,0,127,0)
	line(127,127)
	line(127,0)
	line(0,0)

	line(1,1,1,126,1)
	line(126,126)
	line(126,1)
	line(1,1)

	line(2,2,2,125,2)
	line(125,125)
	line(125,2)
	line(2,2)
end

function draw_sprite(sprite,pos,mpos)
	spr(sprite,pos.x*8+4+mpos.x,pos.y*8+4+mpos.y)
end

function get_block(blocks,pos)
	for b in all(blocks) do
		if b.pos:equal(pos) then
			return b
		end
	end
end

function get_entity_at(state,pos)
	if state.player.pos:equal(pos) then
 	return state.player,9
 end
 
 for b in all(state.blocks) do
 	if b.pos:equal(pos) then
 		return b,10
 	end
 end
 
 return nil,nil
end
-->8
-- state win, lose

function state_win(steps)
	local state = {}
	
	sfx(40)
	
	levels[level]=lvl_complete
	dset(level,levels[level])
	
	if level < 24 then
		levels[level+1]=lvl_ready
		dset(level+1,levels[level+1])
		
		level= level+1
		dset(0,level)
	end
	
	function state:update()
		if btnp(🅾️) then
			if level==24 then
				return
			end
		 del(state_stack,state_stack[#state_stack])
		 del(state_stack,state_stack[#state_stack])
			add(state_stack, state_game(level))
		end
		
		if btnp(❎) then
			del(state_stack,state_stack[#state_stack])
		 del(state_stack,state_stack[#state_stack])
		end
	end
	
	function state:draw()
		rectfill(21,43,106,90,15)
		rect(20,42,107,91,14)
		
		local steps_str=tostr(steps)
		
		print("you escaped the loop",24,50,14)
		print("in "..steps_str.." steps!",45-(#steps_str/2)*4,58,14)
		if level < 24 then
			print("🅾️ next level",38,70,14)
		end
		print("❎ back to menu",34,80,14)
	end
	
	return state
end


function state_lose()
	local state = {}
	
	sfx(30)
	reset_frame()
	
	function state:update()
		if btnp(🅾️) then
		 del(state_stack,state_stack[#state_stack])
		 del(state_stack,state_stack[#state_stack])
			add(state_stack, state_game(level))
		end
		
		if btnp(❎) then
			del(state_stack,state_stack[#state_stack])
		 del(state_stack,state_stack[#state_stack])
		end
	end
	
	function state:draw()
		rectfill(2,8,125,58,0)
		rect(1,7,126,59,9)
		
		if flr(frame/16)%4<3 then
			print("software failure",34,10,9)
			print("you are in unallocated memory",7,18,9)
			print("guru mediation #00042.13378008",5,26,9)
		end
		
		print("🅾️ restart",44,40,9)
		print("❎ back to menu",34,50,9)
	end
	
	return state
end
-->8
-- command blocks
loop_spr=48
reset_spr=49
goal_spr=52
doorc_spr=55
pusherc_spr=56
teleport_spr=50
laserc_spr=58

function reset_block(pos)
	local block={
		pos=pos,
		mpos=vector(0,0),
		sprite=reset_spr,
	}
	
	function block:execute(state)
		state.player.pos=state.player_spawn
	end
	
	return block
end

function loop_block(pos)
	local block={
		pos=pos,
		mpos=vector(0,0),
		sprite=loop_spr,
	}
	
	function block:execute(state)
		state.addr=0
	end
	
	return block
end

function goal_block(pos)
	local block={
		pos=pos,
		mpos=vector(0,0),
		sprite=goal_spr,
	}
	
	function block:execute(state)
		add(state_stack, state_win(state.steps))
		return true
	end
	
	return block
end

function door_block(pos)
	local block={
		pos=pos,
		mpos=vector(0,0),
		sprite=doorc_spr,
	}
	
	function block:execute(state)
		sfx(15)
		state:toggle_doors()
	end
	
	return block
end

function teleport_block(pos)
	local block={
		pos=pos,
		mpos=vector(0,0),
		sprite=teleport_spr,
	}
	
	function block:execute(state)
		sfx(5)
		state.teleporters_active=true
		state.teleporters_active_frame=frame
			
		local mutations={}
		
		for i=1,#state.teleporters do
			local source=state.teleporters[i]
			
			
	 	local t=get_entity_at(state,source)
	 	if t != nil then
	 		local destidx = i+1
				if destidx == #state.teleporters + 1 then
					destidx = 1
				end
				local dest=state.teleporters[destidx]
	 		add(mutations,{t,dest})
	 	end
		end
		
		for m in all(mutations) do
			m[1].pos=m[2]
		end
	end
	
	return block
end


function pusher_block(pos)
	local block={
		pos=pos,
		mpos=vector(0,0),
		sprite=pusherc_spr,
	}
	
	function block:execute(state)
		for p in all(state.pushers) do
			p:toggle(state)
		end
	end
	
	return block
end

function laser_block(pos)
	local block={
		pos=pos,
		mpos=vector(0,0),
		sprite=laserc_spr,
	}
	
	function block:execute(state)
		state.fire_lasers=true
	end
	
	return block
end
-->8
-- static entities

function address(num,direction,sprite,pos)
	local addr={
		num=num,
		pos=pos,
		sprite=sprite,
	}
	
	function addr:execute(state)
		local target=pos:add(direction)
		local b=get_block(state.blocks,target)
		if b != nil then
			return b:execute(state)
		end
		return false
	end
	
	return addr
end

function laser(pos,direction)
	local s={
		pos=pos,
		direction=direction,
		firing=false,
		firing_frame=0,
		last_frame=0,
		dest=pos,
		blocker_type=nil,
	}
		
	function s:fire(game)
		local blocked=false
		local entity=nil
		local blocker_type=nil
		
		while not blocked do
			s.dest=s.dest:add(dirs[s.direction])
			blocked,blocker_type=game:is_blocked(s.dest)
			if not blocked then
				entity,blocker_type=get_entity_at(game,s.dest)
				if entity != nil then
					blocked=true
				end
			end
		end
		
		self.blocker_type=blocker_type
		
		printh(blocked,"debug")
		printh(blocker_type,"debug")
		
		self.firing=true
		self.firing_frame=frame
		self.last_frame=frame
		sfx(35)
	end
	
	function s:update(game)
		if not self.firing then
			return
		end
		
		if frame==self.last_frame then
			return
		end
		
		if frame-self.firing_frame == 8 then
			self.firing=false
			self.firing_frame=0
			self.last_frame=0
			self.dest=self.pos
			sfx(35,-2)
		end
			
		if frame-self.firing_frame == 3 then
			-- blow up block
			if self.blocker_type==nil then
				return
			end
			
 		if self.blocker_type==0 then
 			add(game.explosions,explosion(vector(self.dest.x*8+8,self.dest.y*8+8),{4,5,2,3}))
 			game.memmap[self.dest.y*15+self.dest.x+1]=0
 		elseif self.blocker_type==1 then
 			add(game.explosions,explosion(vector(self.dest.x*8+8,self.dest.y*8+8),{10,11,2,3}))
 			game:remove_door_at(self.dest)
 		elseif self.blocker_type==2 then
 			add(game.explosions,explosion(vector(self.dest.x*8+8,self.dest.y*8+8),{4,5,10,11,2,3}))
 			game:remove_pusher_at(self.dest)
 		elseif self.blocker_type==4 then
 			add(game.explosions,explosion(vector(self.dest.x*8+8,self.dest.y*8+8),{8,9,10,11,2,3}))
 			game:remove_laser_at(self.dest)
 		elseif self.blocker_type==9 then
 			printh("dead","debug")
 			game.player.dead=true
				add(game.explosions,explosion(vector(self.dest.x*8+8,self.dest.y*8+8),{4,5,6,14,15}))
 		elseif self.blocker_type==10 then
 			game:remove_block_at(s.dest)
				add(game.explosions,explosion(vector(self.dest.x*8+8,self.dest.y*8+8),{1,2,5,6,7}))
 		end
		end
	end
	
	function s:draw()
		if self.firing then
			local p=self.pos
			local d=self.dest
			rectfill(p.x*8+7,p.y*8+7,d.x*8+8,d.y*8+8,8)
		end
		draw_sprite(37+self.direction,self.pos,vector(0,0))
	end
		
	return s
end
-->8
-- mobs
p_spr_r={1,2}
p_spr_l={3,4}

function player(pos)
	local s={
		pos=pos,
		mpos=vector(0,0),
		direction=nil,
		flipped=false,
		pushing=nil,
		mov_last_frame=0,
		anim=0,
		last_anim_frame=0,
		dead=false,
	}
	
	function s:attach(b)
		self.pushing=b
	end
	
	function s:move(direction)
		self.direction=direction
		self.mov_last_frame=frame
		
		if self.direction == dirs[1] then
			self.flipped=true
		elseif self.direction == dirs[2] then
			self.flipped=false
		end
	end
	
	function s:move_towards()
		if frame == self.mov_last_frame then
			return false
		end
		self.mov_last_frame=frame
		
		self.mpos=self.mpos:add(self.direction)
		if self.pushing != nil then
			self.pushing.mpos=self.pushing.mpos:add(self.direction)
		end
		
		if self.mpos:mag() >= 8 then
			self.pos=self.pos:add(self.direction)
			self.mpos=vector(0,0)
			
			if self.pushing != nil then
				self.pushing.pos=self.pushing.pos:add(self.direction)
				self.pushing.mpos=vector(0,0)
				self.pushing=nil
			end
			
			self.direction=nil
			return true
		end
		return false
	end
	
	function s:draw()
		if frame-self.last_anim_frame > 6 then
			self.anim=(self.anim+1)%2
			self.last_anim_frame=frame
		end
		
		local sprite=p_spr_r[self.anim+1]
		if self.flipped then
			sprite=p_spr_l[self.anim+1]
		end
		draw_sprite(sprite,self.pos,self.mpos)
	end
	
	return s
end

function pusher(pos)
	local s={
		pos=pos,
		arms={},
		extended=false,
		animating=false,
		animated_frames=0,
	}
	
	function s:toggle(game)
		self.extended = not self.extended
		self.animating=true
		
		if self.extended then
			sfx(25,1)
			for i=1,4 do
				if not game:is_blocked(pos:add(dirs[i])) then
					self:add_arm(dirs[i],game)
				end
			end
		else 
			sfx(26,1)
		end
		
	end
	
	function s:add_arm(direction,game)
		local a=pusher_arm(pos,direction)
				
		local p=nil
		local search=pos
		repeat
			search=search:add(direction)
			p=get_entity_at(game,search)
			
			if p != nil then
				add(a.pushing,p)
			end
		until p==nil
	
		add(self.arms,a)
	end
	
	function s:update(game)
		if not self.animating then
			return
		end
		
		for a in all(self.arms) do
			a:update(self.extended)
		end
		
		self.animated_frames=self.animated_frames+1
		if self.animated_frames >= 4 then
			self.animating=false
			self.animated_frames=0
			
			for a in all(self.arms) do
				for p in all(a.pushing) do
					p.pos=p.pos:add(a.direction)
					p.mpos=vector(0,0)
					
					if game:is_blocked(p.pos) then
						if p==game.player then
							game.player.dead=true
							add(game.explosions,explosion(vector(p.pos.x*8+8,p.pos.y*8+8),{4,5,6,14,15}))
							sfx(0,1)
						else
							del(game.blocks,p)
							add(game.explosions,explosion(vector(p.pos.x*8+8,p.pos.y*8+8),{1,2,5,6,7}))
							sfx(0,1)
						end
					end
				end
				a.pushing={}
			end
			
			if not self.extended then
				self.arms={}
			end
		end
	end
	
	function s:draw()
		for a in all(self.arms) do
			a:draw()
		end
	
		draw_sprite(pusher_spr,self.pos,vector(0,0))
	end
	
	return s
end

arm_sprites={34,35,36,37}

function pusher_arm(pos,direction)
	local s={
		pos=pos,
		mpos=vector(0,0),
		direction=direction,
		pushing={},
		mov_last_frame=0,
	}
	
	function s:update(extend)
		if extend then
			-- fully extended so we good
			if self.mpos:mag() >= 8 then
				return
			end
			self.mpos=self.mpos:add(self.direction:mul(2))
			
			for p in all(self.pushing) do
				p.mpos=p.mpos:add(self.direction:mul(2))
			end
		else
			-- fully retracted so we good
			if self.mpos:mag() == 0 then
				return
			end
			self.mpos=self.mpos:sub(self.direction:mul(2))
			
			for p in all(self.pushing) do
				p.mpos=p.mpos:sub(self.direction:mul(2))
			end
		end
	end
	
	function s:draw()
		if self.direction==dirs[1] then
			draw_sprite(arm_sprites[1],self.pos,self.mpos)
		elseif self.direction==dirs[2] then
			draw_sprite(arm_sprites[2],self.pos,self.mpos)
		elseif self.direction==dirs[3] then
			draw_sprite(arm_sprites[3],self.pos,self.mpos)
		elseif self.direction==dirs[4] then
			draw_sprite(arm_sprites[4],self.pos,self.mpos)
		end
	end
	
	return s
end
-->8
-- particles

function explosion(pos,colors)
	local s= {
		pos=pos,
		p={},
		frame=frame,
	}
	
	for i=0,40 do
		add(s.p,{pos,vector(cos(rnd())+4*(rnd()-0.5),sin(rnd())+4*(rnd()-0.5)),colors[flr(rnd(#colors))]})
	end
	
	function s:update()
		if frame-self.frame > 50 then
			self.p={}
			return
		end
		
		for p in all(self.p) do
			p[1]=p[1]:add(p[2])
		end
	end
	
	function s:draw()
		for p in all(self.p) do
			pset(p[1].x,p[1].y,p[3])
		end
	end
	
	return s
end
__gfx__
000000000006660000000000006660000000000000011100000000000011100000000000000000000000000000000000000000000000000000cccc000ccccc00
00000000006fff000006660000fff600006660000018880000011100008881000011100000000000000000000000000000000000000000000c0000c0ccdddcc0
0000000000fefe00006fff0000efef0000fff600008989000018880000989800008881000000000000000000000000000000000000000000c00dd00cccdcdcc0
0000000000ffff0000fefe0000ffff0000efef00008888000089890000888800009898000000000000000000000000000000000000000000c0dddd0cccdcdcc0
000000000057750000ffff000057750000ffff0000cddc000088880000cddc00008888000000000000000000000000000000000000000000c0dddd0cccdcdcc0
000000000f5575f0005775f00f5575f0005775f008ccdc8000cddc8008ccdc8000cddc800000000000000000000000000000000000000000c0d00d0cccdddcc0
00000000005555000f557500005555000f55750000cccc0008ccdc0000cccc0008ccdc0000000000000000000000000000000000000000000c0000c0ccccccc0
000000000040040000400400004004000040040000100100001001000010010000100100000000000000000000000000000000000000000000cccc000caaac00
4444444400cccc0000cccc0000cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
455555540c0000c00c0000c00caaaac0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45555554c00dd00cc00dd00ccaaddaac000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45555554c0dddd0cc0d00d0ccadbbdac000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45555554c0dddd0cc0d00d0ccadbbdac000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45555554c0d00d0cc00dd00ccaaddaac000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
455555540c0000c00c0000c00caaaac0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4444444400cccc0000cccc0000cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa00aaaa000000000000000000055555500004400000aaaaaaaaaaaa0000b00b00aaaaaaaa000000000000000000000000000000000000000000000000
abbbbbba0abaaba0500000000000000500044000000440000aabbbaaaabbbaa00aabbaa0aabbbbaa000000000000000000000000000000000000000000000000
abbbbbbaabbbbbba50000000000000050004400000044000ba8989baab8989abaa8989aaab8989ba000000000000000000000000000000000000000000000000
abbbbbbaaabbbbaa544444444444444500044000000440000b9898baab9898b0ab9898baab9898ba000000000000000000000000000000000000000000000000
abbbbbbaaabbbbaa544444444444444500044000000440000b8989baab8989b0ab8989baab8989ba000000000000000000000000000000000000000000000000
abbbbbbaabbbbbba50000000000000050004400000044000ba9898baab9898abab9898baaa9898aa000000000000000000000000000000000000000000000000
abbbbbba0abaaba0500000000000000500044000000440000aabbbaaaabbbaa0aabbbbaa0aabbaa0000000000000000000000000000000000000000000000000
aaaaaaaa00aaaa000000000000000000000440000555555000aaaaaaaaaaaa00aaaaaaaa00b00b00000000000000000000000000000000000000000000000000
06666660066666600666666000000000066666600000000000000000066666600666666000000000066666600000000000000000000000000000000000000000
64444446644444466444444600000000644444460000000000000000644444466444444600000000644444460000000000000000000000000000000000000000
64777746644774466447744600000000644ee446000000000000000064aaaa46644aa44600000000648989460000000000000000000000000000000000000000
6444474664777746647447460000000064effe46000000000000000064abba4664abba4600000000649898460000000000000000000000000000000000000000
6474474664777746647447460000000064effe46000000000000000064abba4664abba4600000000648989460000000000000000000000000000000000000000
64777746647447466447744600000000644ee446000000000000000064aaaa46644aa44600000000649898460000000000000000000000000000000000000000
64444446644444466444444600000000644444460000000000000000644444466444444600000000644444460000000000000000000000000000000000000000
06666660066666600666666000000000066666600000000000000000066666600666666000000000066666600000000000000000000000000000000000000000
0cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc0
cccdddcccccddccccccdddcccccdddcccccdcdcccccdddcccccdcccccccdddcccccdddcccccdddcccccdddcccccdddccccccddcccccddccccccdddcccccdddcc
accdcdccacccdcccaccccdccaccccdccaccdcdccaccdccccaccdccccaccccdccaccdcdccaccdcdccaccdcdccaccdcdccaccdccccaccdcdccaccdccccaccdcccc
accdcdccacccdcccaccdddccacccddccaccdddccaccdddccaccdddccaccccdccaccdddccaccdddccaccdddccaccddcccaccdccccaccdcdccaccddcccaccddccc
accdcdccacccdcccaccdccccaccccdccaccccdccaccccdccaccdcdccaccccdccaccdcdccaccccdccaccdcdccaccdcdccaccdccccaccdcdccaccdccccaccdcccc
cccdddcccccdddcccccdddcccccdddcccccccdcccccdddcccccdddcccccccdcccccdddcccccccdcccccdcdcccccdddccccccddcccccdddcccccdddcccccdcccc
0cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc0
ccdddcccccddccccccdddcccccdddcccccdcdcccccdddcccccdcccccccdddcccccdddcccccdddcccccdddcccccdddccccccddcccccddccccccdddcccccdddccc
ccdcdccacccdcccaccccdccaccccdccaccdcdccaccdccccaccdccccaccccdccaccdcdccaccdcdccaccdcdccaccdcdccaccdccccaccdcdccaccdccccaccdcccca
ccdcdccacccdcccaccdddccacccddccaccdddccaccdddccaccdddccaccccdccaccdddccaccdddccaccdddccaccddcccaccdccccaccdcdccaccddcccaccddccca
ccdcdccacccdcccaccdccccaccccdccaccccdccaccccdccaccdcdccaccccdccaccdcdccaccccdccaccdcdccaccdcdccaccdccccaccdcdccaccdccccaccdcccca
ccdddcccccdddcccccdddcccccdddcccccccdcccccdddcccccdddcccccccdcccccdddcccccccdcccccdcdcccccdddccccccddcccccdddcccccdddcccccdccccc
0cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc00cccccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac00
ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0
ccdddcc0ccddccc0ccdddcc0ccdddcc0ccdcdcc0ccdddcc0ccdcccc0ccdddcc0ccdddcc0ccdddcc0ccdddcc0ccdddcc0cccddcc0ccddccc0ccdddcc0ccdddcc0
ccdcdcc0cccdccc0ccccdcc0ccccdcc0ccdcdcc0ccdcccc0ccdcccc0ccccdcc0ccdcdcc0ccdcdcc0ccdcdcc0ccdcdcc0ccdcccc0ccdcdcc0ccdcccc0ccdcccc0
ccdcdcc0cccdccc0ccdddcc0cccddcc0ccdddcc0ccdddcc0ccdddcc0ccccdcc0ccdddcc0ccdddcc0ccdddcc0ccddccc0ccdcccc0ccdcdcc0ccddccc0ccddccc0
ccdcdcc0cccdccc0ccdcccc0ccccdcc0ccccdcc0ccccdcc0ccdcdcc0ccccdcc0ccdcdcc0ccccdcc0ccdcdcc0ccdcdcc0ccdcccc0ccdcdcc0ccdcccc0ccdcccc0
ccdddcc0ccdddcc0ccdddcc0ccdddcc0ccccdcc0ccdddcc0ccdddcc0ccccdcc0ccdddcc0ccccdcc0ccdcdcc0ccdddcc0cccddcc0ccdddcc0ccdddcc0ccdcccc0
0ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc00
0ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc00
ccdddcc0ccddccc0ccdddcc0ccdddcc0ccdcdcc0ccdddcc0ccdcccc0ccdddcc0ccdddcc0ccdddcc0ccdddcc0ccdddcc0cccddcc0ccddccc0ccdddcc0ccdddcc0
ccdcdcc0cccdccc0ccccdcc0ccccdcc0ccdcdcc0ccdcccc0ccdcccc0ccccdcc0ccdcdcc0ccdcdcc0ccdcdcc0ccdcdcc0ccdcccc0ccdcdcc0ccdcccc0ccdcccc0
ccdcdcc0cccdccc0ccdddcc0cccddcc0ccdddcc0ccdddcc0ccdddcc0ccccdcc0ccdddcc0ccdddcc0ccdddcc0ccddccc0ccdcccc0ccdcdcc0ccddccc0ccddccc0
ccdcdcc0cccdccc0ccdcccc0ccccdcc0ccccdcc0ccccdcc0ccdcdcc0ccccdcc0ccdcdcc0ccccdcc0ccdcdcc0ccdcdcc0ccdcccc0ccdcdcc0ccdcccc0ccdcccc0
ccdddcc0ccdddcc0ccdddcc0ccdddcc0ccccdcc0ccdddcc0ccdddcc0ccccdcc0ccdddcc0ccccdcc0ccdcdcc0ccdddcc0cccddcc0ccdddcc0ccdddcc0ccdcccc0
ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0ccccccc0
0caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac000caaac00
01010101011201010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010112730012010125210101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010112921201010101010100010101010101010101010101010101000101010101010101010101010101010001010101010192010101010101010100
0101071223831401010003022101010001010000000000000000007700010100010100000000000000018201620101000101010101010101010101f701010100
01010000000000124300000000010100010111010000120000000000020101000101000000000011000000000001010001010101000000010000000000010100
01010312000101010100120012010100010100122121000012210200000101000101000025430000000123016201010001010057004737270000014301010100
01010000000005214300000000010100010100010202010002120102000101000101058300000073001223218401010001010101007300010000000000010100
01010000000000340100020000010100010100000000000000000000000101000101000000000000000123016201010001010000831200000100010000010100
010100000000000043000000000101000172000000000000000101000001010001011521131200000012232194010100010100110021024312a3210000010100
010100000000010101000000000101000101010101010101010101010101010001010000000000000001230162010100010165007302027301140103e4010100
0101000000000000210000000001010001010000000002000000000000010100010125212312000000122321a401010001010601000000010000001200010100
01010000230000440100120200010100010101070117273747576700010101000101000000000000000123016201010001010001000101000100010000010100
0101000000000000000000000001010001010001000101011202000200010100010135212312010201122321b401010001010112000016017503001364010100
01010000230001010100210000010100010101030100000000000000010101000105a3000000000011011201620101000101750100011183000401d401010100
0101000000000000000000000001010001011201020000010102000000620100010145212312024301122321c401010001010101020101010101001201010100
01010000230000540100430002010100010101000000000000000000010101000101000000000000000123016201010001010001000101010100010001010100
010100150000002100000024000101000101000000000001011201000001010001015521231201010112a321d401010001012700000047010000000000010100
0101110073000101010021000001010001010100000000000000000001010100010100000000000000012301620101000101850173020202020162c401010100
01010035000101030101004400010100010102000112000200000000020101000101652123120000000000010101010001010023008300010000000000010100
0101000083000064010002000001010001010100008303132373830001010100010100000000000000012301620101000101000100010112a300010001010100
010100550001009600012364000101000101010101010101010101430101010001017521231200000000000123e4010001010101210101010000210000010100
010100000000010101852183120101000101010000000000000000000101010001010000150300000001230162010100010100009600a60000b6000001010100
01010075830100110001a38400010100010183a3732383a3a37323000301010001010000000000000000000103f4010001010000361200010000000000010100
01010000000000740100000000010100010101110000000043210000010101000101000000000000000192016201010001010101010101010101010101010100
01010000000100000001000000010100010106162636465666768696a60101000101000000008282820000020202010001015513000000620000000000620100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
01010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100
__label__
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbhhbbhbbbhhhh88hhhhh88hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbhhhbhbhbhbhhhh8hhhhhhh8hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhbhbhbbhhhh88hhhhhhh88hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbhhhbhbhbhbhhhh8hhhhhhh8hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbhhhbbhhbhbhhhh88hhhhh88hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhooohohohhhhhh33hh33h3h3h333hh33h333hh33h333h333hh33h333h333h333hh33hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhohohohohhhhh3hhh3h3h3h3h3h3h3hhhh3hh3h3h3h3h3hhh3hhh3h3h333h3hhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhoohhooohhhhh333h3h3h3h3h333h333hh3hh3h3h33hh33hh3hhh333h3h3h33hh333hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhohohhhohhhhhhh3h3h3h3h3h3hhhhh3hh3hh3h3h3h3h3hhh3h3h3h3h3h3h3hhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhooohooohhhhh33hh33hhh33h3hhh33hhh3hh33hh3h3h333h333h3h3h3h3h333h33hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccccccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhh333333333hhh333333333hhcssssssssschhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhh333333333hhh333333333hhcssssssssschhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhh3bbb3bb33hhh3bbb3bbb3hhcscccscccschhopppopopohhhopppopppohhhopppopooohhhopppopppohhhopppopppohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhh3b3b33b33hhh3b3b333b3hhcscscssscschhopopopopohhhopopopooohhhopopopooohhhopopooopohhhopopopopohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhh3b3b33b33hhh3b3b3bbb3hhcscscssccschhopopopppohhhopopopppohhhopopopppohhhopopooopohhhopopopppohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhh3b3b33b33hhh3b3b3b333hhcscscssscschhopopooopohhhopopooopohhhopopopopohhhopopooopohhhopopopopohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhh3bbb3bbb3hhh3bbb3bbb3hhcscccscccschhopppooopohhhopppopppohhhopppopppohhhopppooopohhhopppopppohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhh333333333hhh333333333hhcssssssssschhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhh333333333hhh333333333hhcssssssssschhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccccccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhopppopppohhhoppoopppohhhoppooppoohhhoppoopppohhhoppoopppohhhoppoopopohhhoppoopppohhhoppoopooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhopopopopohhhoopoopopohhhoopooopoohhhoopoooopohhhoopoooopohhhoopoopopohhhoopoopooohhhoopoopooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhopopopppohhhoopoopopohhhoopooopoohhhoopoopppohhhoopoooppohhhoopoopppohhhoopoopppohhhoopoopppohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhopopooopohhhoopoopopohhhoopooopoohhhoopoopooohhhoopoooopohhhoopoooopohhhoopoooopohhhoopoopopohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhopppooopohhhopppopppohhhopppopppohhhopppopppohhhopppopppohhhopppooopohhhopppopppohhhopppopppohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhoppoopppohhhoppoopppohhhoppoopppohhhopppopppohhhopppoppoohhhopppopppohhhopppopppohhhopppopopohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhoopoooopohhhoopoopopohhhoopoopopohhhooopopopohhhooopoopoohhhooopooopohhhooopooopohhhooopopopohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhoopoooopohhhoopoopppohhhoopoopppohhhopppopopohhhopppoopoohhhopppopppohhhopppooppohhhopppopppohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhoopoooopohhhoopoopopohhhoopoooopohhhopooopopohhhopoooopoohhhopooopooohhhopooooopohhhopooooopohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhopppooopohhhopppopppohhhopppooopohhhopppopppohhhopppopppohhhopppopppohhhopppopppohhhopppooopohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhooooooooohhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhssshssshssshhsshhsshhhhhhssssshhhhhhssshhsshhhhhssshshhhssshshshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshshshshshhhshhhshhhhhhhsshhhsshhhhhhshhshshhhhhshshshhhshshshshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhssshsshhsshhssshssshhhhhsshshsshhhhhhshhshshhhhhssshshhhssshssshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshhhshshshhhhhshhhshhhhhsshhhsshhhhhhshhshshhhhhshhhshhhshshhhshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhshhhshshssshsshhsshhhhhhhssssshhhhhhhshhsshhhhhhshhhssshshshssshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh

__gff__
0000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000
1010000000000000000000000010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000
1010000000000000000000000010100010100000000000000000000000101000101000000000000000000000001010001010000000000010000000000010100010100000000000100000000000101000101000000000000000000000001010001010101010101010101010101010100010100000000000000000000000101000
1010000000000000000000000010100010100000000000300000000000101000101000003400000000000000001010001010000011000010000031000010100010100000000000100000004000101000101000000000500034000000001010001010707172737475767778797a10100010100000001010101010004300101000
101000000000000f000000000010100010100000000000000000000000101000101000101010101010101000101010001010500000000010000000000010100010100000000000100011004100101000101000000000000000000000001010001010000000000000001000000010100010100000001055001010340000101000
1010000000000000000000000010100010100000000000000000000000101000101000101010101000000000301010001010510000000010000000000010100010100000000000100000004200101000101000000000000000000000001010001010341010101010310000300010100010100000001010314010001010101000
1010000000000000000000000010100010100000000000000000000000101000101011101010101060616263641010001010520000000010000000000010100010100000000000100000004300101000101000000000000000000000001010001010001010101011001000000010100010101010001010001010711010101000
1010000000000000000000000010100010101010101010101010101010101000101010101010101010101010101010001010530000000010000000000010100010100000000000100000004400101000101000000000000000000000001010001010001010101000101000000010100010101000310000110000300010101000
1010000000000000000000000010100010101011000000000000000010101000101000000000000000000000001010001010000000314410000000000010100010100000000000100000004500101000101000510000000000000042001010001010001010101000101000000010100010101000641000000000106610101000
1010101010101010101010101010100010101000000000000000000010101000101000000000003400000000001010001010550000000010000000000010100010100000000000100000004600101000101000530010103010100044001010001010000000000000101000340010100010101010100000000000101010101000
101000410010007500100079001010001010100000707172737400001010100010100000000000000000000000101000101056000000001000000e000010100010100000000000100000004700101000101000550010006900100046001010001010101010101010101000000010100010100000000000000000523100101000
1010601052105410461058107a10100010101010101010103034101010101000101000000000000000000000001010001010573000000010000000000010100010100000000000100034004800101000101000570010001100100048001010001010101010101010101010101010100010100000000000000000000000101000
1010111000730010006700103410100010101010101010100010101010101000101000000000000000000000001010001010583400000010000000000010100010100000000000100000000000101000101000000010000000100000001010001010101010101010101010101010100010100000000000000000000000101000
1010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000
1010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000
1010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000
1010000000000000000000000010100010101010101010101010101010101000101010101010101010101010101010001010000000000010000000000010100010100000000000707172737400101000101010101010101010101010101010001010107000000011000020741010100010107010711072107410751076101000
1010000000000037000000000010100010101071100000101010101010101000101000000058001010101010101010001010000000000010000000000010100010100000000000000031000000101000101010000000107071101010101010001010101200000010100010301010100010100010001000000000370000101000
1010000000000000000000000010100010101000100000100000000000101000101000001010307220451010101010001010000000000010000000000010100010100000110000003000000000101000101010001234201237001010101010001010101010377210751056001010100010103410003000001010100030101000
1010000000000000000000000010100010101037100000102000007300101000101000001000302031200034201010001010001100000010000000000010100010100000000000000000000000101000101010000000003110001010101010001010101010003112320010101010100010100010211000001010100021101000
1010000000000000000000000010100010100000000000103100003000101000101010101000101000101010671010001010000000001010100000730010100010100000000000000000340000101000101010101010123700001072731010001010572010612010101000120010100010210010101000000010000010101000
1010101010101010101010101010100010100000001100206000000000101000101076707120101020731010101010001010000000001210120000300010100010101010101010100000000000101000101010101010101020101032301010001010582010106310100000000010100010100000001000210010001010101000
1010000020002000200020107110100010100000000000100000340042101000101000003711000030201010101010001010000000001010100000000010100010100000003245100000120000101000101010101010101020101010101010001010592010101010102020202010100010100021001000000010001000431000
1010110020002000002000103710100010101010101010100000000000101000101010106410101030101010101010001010000000000010000000000010100010100000000046100000000000101000101010101010101020101010101010001010003410101010102020202010100010100000001000000021000038101000
1010101010101010102000101010100010101010101010101010101010101000101010101010001020491000101010001010000000000010000000000010100010100000001247100000000000101000101010101010120000001210101010001010000000101010000000000010100010100000002000000010000000101000
1010003020002000002000107310100010101010101010101010101010101000101010101010101010101010101010001010707172007410000000000010100010100000003148100000000000101000101010101010120011001210101010001010000000101010000000000010100010100021001000210010001100101000
1010606220002000200020103410100010101010101010101010101010101000101010101010101010101010101010001010101032103410000000000010100010100000003049100000000000101000101010101010101010101010101010001010001200000000000000000010100010100000002000000010000000101000
1010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000
1010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000101010101010101010101010101010001010101010101010101010101010100010101010101010101010101010101000
__sfx__
0005000031670376703a6703c6703b6703966034660316502e6402c6402b6402b6402b64029630286302763026630256202362022620206201f6201d6201b6201a62018610166101561012610116100f6100a610
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000b3400f350183502332034330393502e350123400a350063501f340293503135037350333401c350133500d3501a330233302d330343503a36033350243401a3401c330213402e350253501b3500f330
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001b0101b0201b0301b0301b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0301b0301b0201b0201b0201b0201b0101b0101b0101b0000a00009000070000600005000040000200001000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000000001f6501f6501f6501f6501e6501e6501e6501f650286503f65033650246501a65011650076500c65027650346503f6502f650226501d6501e6501e6501e6501e6501e6501d6501d6501d6501d650
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000200501a0501805017050170501705019050190501a0501b0501c0501d0501f05021050250502005000700007000070000700007000070000700007000070000700007000070000700007000070000700
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000f4500f4500f4500f4500f4500f4500f4500f4500f4500f4500f4500f4500f4500f4500f4503045030450304503045030450304503045030450304503045030450304503045030450304503045030450
000100000000030450304503045030450304503045030450304503045030450304503045030450304500f4500f4500f4500f4500f4500f4500f4500f4500f4500f4500f4500f4500f4500f4500f4500f4500f450
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000033150283500d15031350262500f3503b2502565007350181502d6502b65027650226501e6501b65015650136500f6500d6500a65008650056500365002650016500064000640006300062000600
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100031b26023260112601b25023250112501b25023250112501b25023250112501b25023250112501b25023250112501b25023250112501b25023250112501b25023250112501b25023250112501b25023250
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00001f0502405027050290502405027050290502b05027050290502b0502e0503305033050330503305033050330503305133051330513304133041330413303133021330213301133011330113301033010
