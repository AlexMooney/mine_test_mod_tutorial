minetest.register_chatcommand("whereami", {
  privs = { interact = true },
  func = function(name, param)
    local player = minetest.get_player_by_name(name)
    local p = player:getpos()
    return true, p["x"] .. "," .. p["y"] .. "," .. p["z"]
  end
})


minetest.register_chatcommand("placemap", {
  privs = { interact = true },
  func = function(_, param)
    return place_map(param)
  end
})


-- http://lua-users.org/wiki/FileInputOutput
-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end


-- get all lines from a file, returns nil if the file does not exist
function lines_from(file)
  if not file_exists(file) then return nil end
  local lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end


-- load map from file
function place_map(mapname)
  if mapname == "" or mapname == nil then
    return false, "Specify a file name"
  end
  local file = minetest.get_modpath("ascii2map") .. '/' .. mapname
  local lines = lines_from(file)
  if lines == nil then
    return false, "Could not find " .. file
  end

  print("Importing " .. mapname .. "...")

  local settings = lines[1]
  local pos = {}
  pos["x"] = tonumber(string.match(settings, "x=(-?%d+)"))
  pos["y"] = tonumber(string.match(settings, "y=(-?%d+)"))
  pos["z"] = tonumber(string.match(settings, "z=(-?%d+)"))

  local height = tonumber(string.match(settings, "height=(-?%d+)"))
  local roof = tonumber(string.match(settings, "roof=(-?%d+)"))
  local floor = tonumber(string.match(settings, "floor=(-?%d+)"))
  local fill_mat = {name=string.match(settings, "material=(%a+:?%a+)"), param1=0}

  local air = {name="air", param1=0}
  local door_w = {name="doors:door_wood_a", param1=0}
  local door_s = {name="doors:door_wood_a", param1=0, param2=1}
  local door_e = {name="doors:door_wood_b", param1=0}
  local door_n = {name="doors:door_wood_b", param1=0, param2=1}
  local door_hidden = {name="doors:hidden"}

  local function get_local_height(ix, iz, height, lines)
    local local_height = height
    local north = string.sub(lines[ix-1], iz, iz)
    local south = string.sub(lines[ix+1], iz, iz)
    local west = string.sub(lines[ix], iz-1, iz-1)
    local east = string.sub(lines[ix], iz+1, iz+1)

    local wall_like = "[#|%-]"
    if string.find(north, wall_like) then
      local_height = local_height-1
    end
    if string.find(south, wall_like) then
      local_height = local_height-1
    end
    if string.find(east, wall_like) then
      local_height = local_height-1
    end
    if string.find(west, wall_like) then
      local_height = local_height-1
    end
    return local_height
  end

  for ix=3, table.maxn(lines)-1, 1
  do
    for iz=2, string.len(lines[ix])-1, 1
    do
      local char = string.sub(lines[ix], iz, iz)
      local local_height = height
      if char == '.' then
        local_height = get_local_height(ix, iz, height, lines)
      end

      for iy=1-floor, height+roof, 1
      do
        if iy <= 0 or iy > height or char == "#" then
          minetest.set_node({x=pos["x"]+ix, y=pos["y"]+iy, z=pos["z"]+iz}, fill_mat)
        elseif char == "-" or char == "|" then
          if iy == 1 then
            if char == "|" then
              minetest.set_node({x=pos["x"]+ix, y=pos["y"]+iy, z=pos["z"]+iz}, door_w)
            else
              minetest.set_node({x=pos["x"]+ix, y=pos["y"]+iy, z=pos["z"]+iz}, door_s)
            end
          elseif iy == 2 then
            minetest.set_node({x=pos["x"]+ix, y=pos["y"]+iy, z=pos["z"]+iz}, door_hidden)
          else
            minetest.set_node({x=pos["x"]+ix, y=pos["y"]+iy, z=pos["z"]+iz}, fill_mat)
          end
        else
          if iy < local_height then
            minetest.set_node({x=pos["x"]+ix, y=pos["y"]+iy, z=pos["z"]+iz}, air)
          else
            minetest.set_node({x=pos["x"]+ix, y=pos["y"]+iy, z=pos["z"]+iz}, fill_mat)
          end
        end
      end
    end
  end
  print("Successfully imported " .. mapname)
  return true, "Successfully imported " .. mapname
end
