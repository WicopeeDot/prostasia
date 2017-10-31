local tag = "prostasia"

local PLAYER = FindMetaTable("Player")

if not PLAYER.IsFriend then
	MsgC( "["..tag.."]", Color(255,0,0), " lua_helpers required! https://github.com/Re-Dream/lua_helpers/ \n")
	return
end

if not easylua then
	MsgC( "["..tag.."]", Color(255,0,0), " LuaDev required! https://github.com/Noiwex/luadev/ \n")
	return
end

if SERVER then
	util.AddNetworkString(tag.."_propspawned")
	util.AddNetworkString(tag.."_clean")

	prostasia_leavers = {}

	prostasia_howmanymins = 5

	local args = {
		two = {
			"SWEP",
			"SENT",
			"Vehicle",
			"NPC"
		},
		three = {
			"Effect",
			"Prop",
			"Ragdoll"
		}
	}

	local function netshit(ply,ent)
		net.Start(tag.."_propspawned")
		net.WriteTable({
			owner = ply:EntIndex(),
			entity = ent:EntIndex()
		})
		net.Broadcast()
	end

	local function forthree(ply,model,ent)
		ent.Owner = ply
		ent.OSteamID = ply:SteamID()
	end

	local function fortwo(ply,ent)
		ent.Owner = ply
		ent.OSteamID = ply:SteamID()
	end

	for i = 1,4 do
		if(i < #args.three or i == #args.three) then
			hook.Add("PlayerSpawned"..args.three[i], tag.."_onspawn", forthree)
		end

		if(i < #args.two or i == #args.two) then
			hook.Add("PlayerSpawned"..args.two[i], tag.."_onspawn", fortwo)
		end
	end
    
	local ERR_NOTVALID_NOTPLAYER = 1
	local ERR_SOMETHING_GONE_WRONG = 2

	local function check(ply,ent)
		if type(ent) ~= "Player" and IsValid(ent) and IsValid(ent.Owner) then
			return (ent.Owner == ply or ent.Owner:IsFriend(ply) or ply:IsAdmin())
		else
			return 1
		end

		return 2
	end

	hook.Add("PlayerDisconnected", tag.."_disconnect", function(ply)
		prostasia_leavers[ply:SteamID()] = CurTime()
	end)

	local function noticecleanup(steamid)
		for k,v in pairs(player.GetAll()) do
			if v:IsAdmin() == true then
				net.Start(tag.."_clean")
				net.WriteString(steamid)
				net.Send(v)
			end
		end

		for k,v in pairs(ents.GetAll()) do
			if(v.OSteamID == steamid) then
				v:Remove()
			end
		end
	end

	hook.Add("Think", tag.."_think", function()
		for k,v in pairs(prostasia_leavers) do
			if(CurTime()-v > prostasia_howmanymins*60) then
				noticecleanup(k)
				prostasia_leavers[k] = nil
			end
		end
	end)

	hook.Add("PlayerInitialSpawn", tag.."_connect", function(ply)
		prostasia_leavers[ply:SteamID()] = nil
	end)

	hook.Add("PhysgunPickup", tag.."_physpickup", function(ply,ent)
		local chooch = check(ply,ent)

		if(chooch == ERR_SOMETHING_GONE_WRONG) then
			return false
		end

		if(type(chooch) ~= "number") then
			return chooch
		end

		if(type(ent) == "Player") then
			return ent:IsFriend(ply) or ply:IsAdmin()
		end

		return false
	end)

	hook.Add("CanTool", tag.."_toolrestrict", function(ply,tr,tool)
		local ent = tr.Entity
		
		if ent == game.GetWorld() then
			return false
		end
		
		local chooch = check(ply,ent)

		if(chooch == ERR_SOMETHING_GONE_WRONG) then
			return false
		end

		if(type(chooch) ~= "number") then
			return chooch
		end

		return false
	end)
elseif CLIENT then
	net.Receive(tag.."_clean", function()
		local stid = net.ReadString()

		notification.AddLegacy("[PROSTASIA] "..stid.."'s props have been cleaned up!",NOTIFY_CLEANUP,5)
		surface.PlaySound("buttons/lever"..math.random(1,8)..".wav")
	end)
end