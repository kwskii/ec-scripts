-- Get global __EC__ table (available only in EliteCheat environment)
-- and ensure dependencies are loaded
local ec 				= _G["__EC__"]
local eccore 			= ec.requireScript("ec.core")
local checkbox_value = false
if not(ec.actors.isInWorld()) then return end
	
local selfPlayerActorWrapper = getSelfPlayer()
if selfPlayerActorWrapper == nil then  return end

local buylist = {
	[44195] = "Memory Fragment",
	[17340] = "Value Pack (30 Days)",
	[17988] = "Value Pack (30 Days) 2",
	[17583] = "Value Pack (30 Days) 3",
	[17081] = "Blessing of Kamasylve (15 Days)",
	--[40228] = "Pergamino de Letras Antiguas",
	[50807] = "Respiro del bosque",
	[50810] = "Raiz pezuena del pie",
	[50809] = "Caracola de Alga",
	[50804] = "Heno de cola de piedra",
	[50808] = "Gema de Fruta",
	[50806] = "Interior de la bestia"
}
local buylist_add_id    = ""
local buylist_add_name  = ""

local RenderMPOptions = function(ui)
	local remove_id = nil
    for id,name in pairs(buylist) do
		if ui.button("-##mp_remove_buylist"..tostring(id)) then
			remove_id = id
		end
        ui.sameLine()
        ui.text(string.format("%d %s", id, name))
    end
    if remove_id ~= nil then
		buylist[remove_id] = nil
    end

    if buylist then
		ui.separator()
    end
	ui.pushItemWidth(120)
    _, buylist_add_id = ui.inputText("Item ID (Use BDODatabase.net)##mp_buylist_add_id", buylist_add_id)
    ui.popItemWidth()
    ui.pushItemWidth(120)
    _, buylist_add_name = ui.inputText("Description##mp_buylist_add_name", buylist_add_name)
    ui.popItemWidth()
    if ui.button("Add item to the list##mp_add_buylist") then
		local item_id = tonumber(buylist_add_id)
		local item_desc = buylist_add_name
		if type(item_id) == "number" and item_id > 0 and string.len(item_desc) > 0 then
			buylist[item_id] = item_desc;
			buylist_add_id = ""
			buylist_add_name = ""
		end
	end
end

local OnRenderMenu = function(ui)
	if ui.checkbox("Toggle marketplace bot", checkbox_value) then
		checkbox_value = not checkbox_value
		test = not test
	end
	if ui.treeNode("Marketplace Buy List") then
        RenderMPOptions(ui)
        ui.treePop()
    end
end

local wait_until                = 0
function Wait(sec)
    wait_until = os.clock() + sec
end

local ECMarketplaceHandler = function ()
	--- local current_time = os.clock()
	local current_time = os.clock()
	if current_time < wait_until then
		return
	end
	for id,name in pairs(buylist) do
		--ec.log("Checking for " .. name .. "...")
		requestItemMarketSellInfo(1, id, false);
		local target_slot_count = getItemMarketSellInfoInClientCount(1, id)
		--- ec.log("[".. os.date():sub(9) .. "] Target Count : "..target_slot_count)
		local slot_index = 0
		if (target_slot_count ~= 0) then
			while slot_index < target_slot_count
			do
				local sell_info = getItemMarketSellInfoInClientByIndex(1, id, slot_index)
				if(sell_info) then
					local sell_info_count = Int64toInt32(sell_info:getCount())
					if (Int64toInt32(sell_info_count) > 0) then
				
						local is_bidding_item = sell_info:isBiddingItem()
						local is_bidding_join_time = sell_info:isBiddingJoinTime()
						local item_market_no = sell_info:getItemMarketNo()
						local is_bidding_join_item = isBiddingJoinItem(item_market_no)
						
						local one_price = Int64toInt32(sell_info:getTotalPrice() / sell_info:getCount())
						local total_price = Int64toInt32(sell_info:getTotalPrice())
					
						
						if (Int64toInt32(warehouse_moneyFromNpcShop_s64()) > total_price) then
							if (is_bidding_item) then
								if (is_bidding_join_time) then
									if (not is_bidding_join_item) then
										ec.log("Bidding " .. name .. "...")
										requestBuyItemForItemMarket(2, id, slot_index, sell_info_count, 0);
									end
								elseif (is_bidding_join_item) then

									ec.log("Bidding " .. name .. "...")
									requestBuyItemForItemMarket(2, id, slot_index, sell_info_count, 0);
								end
							else
								ec.log("[" .. os.date():sub(9) .. "] Buying " ..  name .. " (" .. slot_index .. "." .. Int64toInt32(sell_info_count) .. "-" .. Int64toInt32(item_market_no) .. ") [T " .. total_price .. " | U " .. one_price .. "]")

								requestBuyItemForItemMarket(2, id, slot_index, sell_info_count, 0);
							end
						end
					end
				end
				slot_index = slot_index+1
			end
		end
	end
	Wait(0.1)
	--Wait(0.025)
end

local OnPulse = function()
	if (checkbox_value) then
		ECMarketplaceHandler()
	end
end

ec.registerEvent("EC.OnPulse", OnPulse)

if ec.main_menu then
	ec.main_menu.AddEntry("Marketplace", OnRenderMenu)
end

