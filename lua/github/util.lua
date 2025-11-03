local M = {}

local root_url = "https://api.github.com/"

local function geturl(url)
	return root_url .. url
end

function M.request(path, args)
	local url = geturl(path)
	local cmd = {
		"curl",
		"-s",
		"-L",
		"-H",
		"Accept: application/vnd.github+json",
		"-H",
		"Authorization: token " .. (vim.env.GITHUB_TOKEN or ""),
		"-H",
		"X-GitHub-Api-Version: 2022-11-28",
	}
	if args and #args > 0 then
		for _, v in ipairs(args) do
			table.insert(cmd, v)
		end
	end
	table.insert(cmd, url)
	local result = table.concat(vim.fn.systemlist(cmd), "\n")

	return vim.json.decode(result)
end

return M
