local function save_filter(msg, name, value)
	local hash = nil
	if msg.to.type == 'channel' then
		hash = 'chat:'..msg.to.id..':filters'
	end
	if msg.to.type == 'user' then
		return 'Just For Group Chat'
	end
	if hash then
		redis:hset(hash, name, value)
		return "Done !"
	end
end

local function get_filter_hash(msg)
	if msg.to.type == 'channel' then
		return 'chat:'..msg.to.id..':filters'
	end
end 

local function list_filter(msg)
	if msg.to.type == 'user' then
		return
	end
	local hash = get_filter_hash(msg)
	if hash then
		local names = redis:hkeys(hash)
		local text = 'List of filtered words:\n______________________________\n'
		for i=1, #names do
			text = text..'-> '..names[i]..'\n'
		end
		return text
	end
end

local function get_filter(msg, var_name)
	local hash = get_filter_hash(msg)
	if hash then
		local value = redis:hget(hash, var_name)
		if value == 'msg' then
			send_large_msg('channel#id'..msg.to.id, 'User @'..msg.from.username.. '\nGet Warn Because Useing Filtered Word')
			delete_msg(msg.id, ok_cb, true)
		    elseif value == 'kick' then
			send_large_msg('channel#id'..msg.to.id, 'User @'..msg.from.username.. '\nKicked Because Using Filtered Word')
			delete_msg(msg.id, ok_cb, true)
			channel_kick_user('channel#id'..msg.to.id, 'user#id'..msg.from.id, ok_cb, true)
			elseif value == 'clean' then
			delete_msg(msg.id, ok_cb, true)
		end
    end
end

local function get_filter_act(msg, var_name)
	local hash = get_filter_hash(msg)
	if hash then
		local value = redis:hget(hash, var_name)
		if value == 'msg' then
			return 'Warn to this word'
		elseif value == 'kick' then
			return 'This word will get forbidden.'
		elseif value == 'clear' then
			return 'This word is get cleaned'
		elseif value == 'none' then
			return 'This word is not filtered'
		end
	end
end

local function run(msg, matches)
	local data = load_data(_config.moderation.data)
	if matches[1] == "ilterlist" then
		return list_filter(msg)
	elseif matches[1] == "ilter" and matches[2]:lower() == "warn" then
		if data[tostring(msg.to.id)] then
			local settings = data[tostring(msg.to.id)]['settings']
			if not is_momod(msg) then
				return "Mods only"
			else
				local value = 'msg'
				local name = string.sub(matches[3]:lower(), 1, 1000)
				local text = save_filter(msg, name, value)
				return text
			end
		end
	elseif matches[1] == "ilter" and matches[2]:lower() == "set" then
		if data[tostring(msg.to.id)] then
			local settings = data[tostring(msg.to.id)]['settings']
			if not is_momod(msg) then
				return "You are not a moderator!"
			else
				local value = 'kick'
				local name = string.sub(matches[3]:lower(), 1, 1000)
				local text = save_filter(msg, name, value)
				return text
				
			end
	end
	elseif matches[1] == "ilter" and matches[2]:lower() == "c" then
		if data[tostring(msg.to.id)] then
			local settings = data[tostring(msg.to.id)]['settings']
			if not is_momod(msg) then
				return "You are not a moderator!"
			else
				local value = 'clean'
				local name = string.sub(matches[3]:lower(), 1, 1000)
				local text = save_filter(msg, name, value)
				return text
				
			end
		end
	elseif matches[1] == "ilter" and matches[2]:lower() == "del" then
		if data[tostring(msg.to.id)] then
			local settings = data[tostring(msg.to.id)]['settings']
			if not is_momod(msg) then
				return "You are not a moderator!"
			else
				local value = 'none'
				local name = string.sub(matches[3]:lower(), 1, 1000)
				local text = save_filter(msg, name, value)
				return text
			end
		end
	elseif matches[1] == "ilter" and matches[2] == "?" then
		return get_filter_act(msg, matches[3]:lower())
	else
		if is_sudo(msg) then
			return
		elseif is_admin(msg) then
			return
		elseif is_momod(msg) then
			return
		elseif tonumber(msg.from.id) == tonumber(our_id) then
			return
		else
			return get_filter(msg, msg.text:lower())
		end
	end
end

return {
	description = "Set and Get Variables", 
	usagehtm = '<tr><td align="center">filter > کلمه</td><td align="right">این دستور یک کلمه را ممنوع میکند و اگر توسط کاربری این کلمه استفاده شود، به او تذکر داده خواهد شد</td></tr>'
	..'<tr><td align="center">filter + کلمه</td><td align="right">این دستور کلمه ای را فیلتر میکند به طوری که اگر توسط کاربری استفاده شود، ایشان کیک میگردند</td></tr>'
	..'<tr><td align="center">filter - کلمه</td><td align="right">کلمه ای را از ممنوعیت یا فیلترینگ خارج میکند</td></tr>'
	..'<tr><td align="center">filter ? کلمه</td><td align="right">با این دستوع اکشن بر روی کلمه ای را میتوانید مشاهده کنید یعنی میتوانید متوجه شوید که این کلمه فیلتر است،ممنوع است یا از فیلترینگ خارج شده</td></tr>',
	usage = {
	user = {
		"filter ? (word) : مشاهده عکس العمل",
		"filterlist : لیست فیلتر شده ها",
	},
	moderator = {
		"filter warn (word) : اخطار کردن لغت",
		"filter set (word) : ممنوع کردن لغت",
		"filter del (word) : حذف از فیلتر",
	},
	},
	patterns = {
		"^[!/][Ff](ilter) (.+) (.*)$",
		"^[!/][Ff](ilterlist)$",
		"^[Ff](ilter) (.+) (.*)$",
		"^[Ff](ilterlist)$",
		"(.*)",
	},
	run = run
}

--shared by @ST_channel_AR
