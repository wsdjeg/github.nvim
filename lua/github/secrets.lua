local M = {}

local util = require("github.util")

function M.list_repository_secrets(user, repo)
	return util.request(table.concat({ "repos", user, repo, "actions/secrets" }, "/"))
end

function M.delete_repository_secret(user, repo, secret_name)
	return util.request(table.concat({ "repos", user, repo, "actions/secrets", secret_name }, "/"), { "-X", "DELETE" })
end

function M.get_repository_secrets_public_key(user, repo)
	return util.request(table.concat({ "repos", user, repo, "actions/secrets/public-key" }, "/"))
end

function M.update_repository_secret(user, repo, secret)
	local key_info = M.get_repository_secrets_public_key(user, repo)
	local key_id = key_info.key_id
	local b64_key = key_info.key
	local ok, sodium = pcall(require, "luasodium")
	if not ok then
		vim.notify("failed to load luasodium module")
		return
	end
	local public_key_bin = vim.base64.decode(b64_key)
	local encrypted_bin = sodium.crypto_box_seal(secret.value, public_key_bin)
	local encrypted_b64 = vim.base64.encode(encrypted_bin)
	local url = table.concat({ "repos", user, repo, "actions/secrets", secret.name }, "/")
	local body = {
		encrypted_value = encrypted_b64,
		key_id = key_id,
	}
	return util.request(url, {
		"-X",
		"PUT",
		"-d",
		vim.json.encode(body),
	})
end

return M
