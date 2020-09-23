pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- ld countdown
-- by soupstoregames

function _init()
	end_time=23*60
	end_time+=5*24*60
end


function _update()
	t=stat(94) //mins
	t+=stat(93)*60 //hrs
	t+=stat(92)*24*60 //days
	
	delta=end_time-t
	 
	secs=60-stat(95)
	mins=flr(delta%60)
	delta/=60
	hours=flr(delta%24)
	delta/=24
	days=flr(delta)
end


cols={}
function _draw()
	cls()
	print(pad(days),0,1,12)
	print(pad(hours),9,1,11)
	print(pad(mins),0,10,9)
	print(pad(secs),9,10,8)

	for y=0,15 do
		cols[y]={}
		for x=0,15 do
			cols[y][x]=pget(x,y)
		end
	end
	
	for y=0,15 do
		for x=0,15 do
			for iy=0,8 do
				for ix=0,8 do
					pset(x*8+ix,y*8+iy,cols[y][x])
				end
			end
		end
	end
end

function pad(str)
	if (#tostring(str)>=2) return str
	return "0"..str
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbb0000000000000000
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbb0000000000000000
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbb0000000000000000
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbb0000000000000000
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbb0000000000000000
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbb0000000000000000
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbb0000000000000000
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbb0000000000000000
cccccccc00000000cccccccc000000000000000000000000cccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb0000000000000000
cccccccc00000000cccccccc000000000000000000000000cccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb0000000000000000
cccccccc00000000cccccccc000000000000000000000000cccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb0000000000000000
cccccccc00000000cccccccc000000000000000000000000cccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb0000000000000000
cccccccc00000000cccccccc000000000000000000000000cccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb0000000000000000
cccccccc00000000cccccccc000000000000000000000000cccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb0000000000000000
cccccccc00000000cccccccc000000000000000000000000cccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb0000000000000000
cccccccc00000000cccccccc000000000000000000000000cccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb0000000000000000
cccccccc00000000cccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccc00000000cccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccc00000000cccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccc00000000cccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccc00000000cccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccc00000000cccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccc00000000cccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccc00000000cccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccc00000000cccccccc00000000cccccccc00000000000000000000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb
cccccccc00000000cccccccc00000000cccccccc00000000000000000000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb
cccccccc00000000cccccccc00000000cccccccc00000000000000000000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb
cccccccc00000000cccccccc00000000cccccccc00000000000000000000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb
cccccccc00000000cccccccc00000000cccccccc00000000000000000000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb
cccccccc00000000cccccccc00000000cccccccc00000000000000000000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb
cccccccc00000000cccccccc00000000cccccccc00000000000000000000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb
cccccccc00000000cccccccc00000000cccccccc00000000000000000000000000000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb00000000bbbbbbbb
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccccccccccccccc00000000cccccccccccccccccccccccc0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbb
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999000000009999999900000000999999999999999999999999000000000000000088888888000000008888888800000000888888888888888888888888
99999999000000009999999900000000999999999999999999999999000000000000000088888888000000008888888800000000888888888888888888888888
99999999000000009999999900000000999999999999999999999999000000000000000088888888000000008888888800000000888888888888888888888888
99999999000000009999999900000000999999999999999999999999000000000000000088888888000000008888888800000000888888888888888888888888
99999999000000009999999900000000999999999999999999999999000000000000000088888888000000008888888800000000888888888888888888888888
99999999000000009999999900000000999999999999999999999999000000000000000088888888000000008888888800000000888888888888888888888888
99999999000000009999999900000000999999999999999999999999000000000000000088888888000000008888888800000000888888888888888888888888
99999999000000009999999900000000999999999999999999999999000000000000000088888888000000008888888800000000888888888888888888888888
99999999000000009999999900000000999999990000000099999999000000000000000088888888000000008888888800000000888888880000000088888888
99999999000000009999999900000000999999990000000099999999000000000000000088888888000000008888888800000000888888880000000088888888
99999999000000009999999900000000999999990000000099999999000000000000000088888888000000008888888800000000888888880000000088888888
99999999000000009999999900000000999999990000000099999999000000000000000088888888000000008888888800000000888888880000000088888888
99999999000000009999999900000000999999990000000099999999000000000000000088888888000000008888888800000000888888880000000088888888
99999999000000009999999900000000999999990000000099999999000000000000000088888888000000008888888800000000888888880000000088888888
99999999000000009999999900000000999999990000000099999999000000000000000088888888000000008888888800000000888888880000000088888888
99999999000000009999999900000000999999990000000099999999000000000000000088888888000000008888888800000000888888880000000088888888
99999999999999999999999900000000999999999999999999999999000000000000000088888888888888888888888800000000888888888888888888888888
99999999999999999999999900000000999999999999999999999999000000000000000088888888888888888888888800000000888888888888888888888888
99999999999999999999999900000000999999999999999999999999000000000000000088888888888888888888888800000000888888888888888888888888
99999999999999999999999900000000999999999999999999999999000000000000000088888888888888888888888800000000888888888888888888888888
99999999999999999999999900000000999999999999999999999999000000000000000088888888888888888888888800000000888888888888888888888888
99999999999999999999999900000000999999999999999999999999000000000000000088888888888888888888888800000000888888888888888888888888
99999999999999999999999900000000999999999999999999999999000000000000000088888888888888888888888800000000888888888888888888888888
99999999999999999999999900000000999999999999999999999999000000000000000088888888888888888888888800000000888888888888888888888888
00000000000000009999999900000000999999990000000099999999000000000000000000000000000000008888888800000000888888880000000088888888
00000000000000009999999900000000999999990000000099999999000000000000000000000000000000008888888800000000888888880000000088888888
00000000000000009999999900000000999999990000000099999999000000000000000000000000000000008888888800000000888888880000000088888888
00000000000000009999999900000000999999990000000099999999000000000000000000000000000000008888888800000000888888880000000088888888
00000000000000009999999900000000999999990000000099999999000000000000000000000000000000008888888800000000888888880000000088888888
00000000000000009999999900000000999999990000000099999999000000000000000000000000000000008888888800000000888888880000000088888888
00000000000000009999999900000000999999990000000099999999000000000000000000000000000000008888888800000000888888880000000088888888
00000000000000009999999900000000999999990000000099999999000000000000000000000000000000008888888800000000888888880000000088888888
00000000000000009999999900000000999999999999999999999999000000000000000000000000000000008888888800000000888888888888888888888888
00000000000000009999999900000000999999999999999999999999000000000000000000000000000000008888888800000000888888888888888888888888
00000000000000009999999900000000999999999999999999999999000000000000000000000000000000008888888800000000888888888888888888888888
00000000000000009999999900000000999999999999999999999999000000000000000000000000000000008888888800000000888888888888888888888888
00000000000000009999999900000000999999999999999999999999000000000000000000000000000000008888888800000000888888888888888888888888
00000000000000009999999900000000999999999999999999999999000000000000000000000000000000008888888800000000888888888888888888888888
00000000000000009999999900000000999999999999999999999999000000000000000000000000000000008888888800000000888888888888888888888888
00000000000000009999999900000000999999999999999999999999000000000000000000000000000000008888888800000000888888888888888888888888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

