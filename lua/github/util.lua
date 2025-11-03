local M = {}

function M.get(path, args)
	local url = geturl(path)
	local cmd = {
		"curl",
		"-s",
		url,
	}
	if #args > 0 then
		for _, v in args do
			table.insert(cmd, v)
		end
	end
	local result = table.concat(vim.fn.systemlist(cmd), "\n")

	return vim.json.decode(result)
end

return M
