-- MLR Pocket: original sample-slice performer inspired by monome mlr.
-- Not the original mlr/MLRE script; runs on Android Softcut.
-- Rows 1-4: play one of 16 sample slices; rows 5-8: stop that voice.
local g=grid.connect(1)
local active={1,1,1,1}
local voices={false,false,false,false}
local slices=16
local rate=1
local level=.7
local playing=true
local duration=2
local path=_path.audio.."factory_loop.wav"
local function updateGrid()
  g:all(0)
  for y=1,4 do
    for x=1,16 do
      g:led(x,y,active[y]==x and voices[y] and 15 or (x<=slices and 3 or 0))
      g:led(x,y+4,voices[y] and 5 or 1)
    end
  end
  g:refresh()
end
local function slice(row,x)
  if x>slices then return end
  local start=(x-1)*duration/slices
  local finish=math.min(duration,start+duration/slices)
  active[row]=x;voices[row]=true
  softcut.loop_start(row,start)
  softcut.loop_end(row,finish)
  softcut.position(row,start)
  softcut.play(row,playing and 1 or 0)
  updateGrid();redraw()
end
function init()
  softcut.buffer_clear()
  softcut.buffer_read_mono(path,0,0,-1,1,1)
  for i=1,4 do
    softcut.enable(i,1);softcut.buffer(i,1)
    softcut.loop(i,1);softcut.loop_start(i,0);softcut.loop_end(i,duration)
    softcut.level(i,level/2);softcut.pan(i,(i-2.5)/3)
    softcut.fade_time(i,.008);softcut.rate(i,rate)
    softcut.play(i,0)
  end
  updateGrid();redraw()
end
g.key=function(x,y,z)
  if z~=1 then return end
  local row=((y-1)%4)+1
  if y<=4 then slice(row,x)
  else voices[row]=false;softcut.play(row,0);updateGrid();redraw() end
end
function redraw()
  screen.clear();screen.level(15)
  screen.move(0,9);screen.text("MLR / POCKET EDITION")
  screen.level(8);screen.move(0,22);screen.text("SLICES "..slices.."  RATE "..string.format("%.2f",rate))
  screen.move(0,35);screen.text("LEVEL "..string.format("%.2f",level))
  screen.move(0,48);screen.text(playing and "PLAY" or "PAUSED")
  screen.level(4);screen.move(0,62);screen.text("K2 STOP  K3 PLAY")
  screen.update()
end
function key(n,z)
  if z~=1 then return end
  if n==2 then
    for i=1,4 do softcut.play(i,0);voices[i]=false end
  elseif n==3 then
    playing=not playing
    for i=1,4 do softcut.play(i,(playing and voices[i]) and 1 or 0) end
  end
  updateGrid();redraw()
end
function enc(n,d)
  if n==1 then slices=util.clamp(slices+d,2,16)
  elseif n==2 then rate=util.clamp(rate+d*.05,-2,2);for i=1,4 do softcut.rate(i,rate) end
  elseif n==3 then level=util.clamp(level+d*.025,0,2);for i=1,4 do softcut.level(i,level/2) end end
  updateGrid();redraw()
end
