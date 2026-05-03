---@diagnostic disable: undefined-global, unused-local

local function parse_scalar(raw)
  local v = raw:gsub("^%s+", ""):gsub("%s+$", "")
  if v == "" then return nil end
  if v == "true" then return true end
  if v == "false" then return false end
  local n = tonumber(v)
  if n ~= nil then return n end
  local dq = v:match('^"(.*)"$')
  if dq ~= nil then return dq end
  local sq = v:match("^'(.*)'$")
  if sq ~= nil then return sq end
  return v
end

local function read_project_variables()
  local flat = {}
  local f = io.open("_variables.yml", "r")
  if not f then return flat end

  local lines = {}
  for line in f:lines() do table.insert(lines, line) end
  f:close()

  local stack = {} -- {indent=N, prefix="a.b"}

  local function current_prefix()
    if #stack == 0 then return "" end
    return stack[#stack].prefix .. "."
  end

  for _, line in ipairs(lines) do
    if line:match("^%s*#") or line:match("^%s*$") then goto continue end

    local spaces = line:match("^(%s*)")
    local indent  = #spaces
    local content = line:sub(indent + 1)

    while #stack > 0 and stack[#stack].indent >= indent do
      table.remove(stack)
    end

    local key, raw = content:match("^([%w_.-]+):%s*(.-)%s*$")
    if key then
      local prefix = current_prefix()
      if raw == "" or raw:match("^#") then
        table.insert(stack, {indent = indent, prefix = prefix .. key})
      else
        local parsed = parse_scalar(raw)
        if parsed ~= nil then flat[prefix .. key] = parsed end
      end
    end

    ::continue::
  end

  return flat
end

return {
  ["show-vars"] = function(_args, _kwargs, _meta)
    local vars  = read_project_variables()
    local items = {}

    if next(vars) ~= nil then
      local keys = {}
      for k in pairs(vars) do table.insert(keys, k) end
      table.sort(keys)

      for _, k in ipairs(keys) do
        local val_str = tostring(vars[k])
        table.insert(items, pandoc.Plain({
          pandoc.Strong({ pandoc.Str(k) }),
          pandoc.Str(": "),
          pandoc.Code(val_str)
        }))
      end
    end

    if #items == 0 then
      return { pandoc.Para({ pandoc.Emph({ pandoc.Str("No variables defined in _variables.yml.") }) }) }
    end

    return { pandoc.BulletList(items) }
  end
}
