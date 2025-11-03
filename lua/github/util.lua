local M = {}

local root_url = "https://api.github.com/"

local function geturl(url)
	return root_url .. url
end

function M.get(path, args)
	local url = geturl(path)
	local cmd = {
		"curl",
		"-s",
		url,
	}
	if args and #args > 0 then
		for _, v in args do
			table.insert(cmd, v)
		end
	end
	local result = table.concat(vim.fn.systemlist(cmd), "\n")

	return vim.json.decode(result)
end

return M
