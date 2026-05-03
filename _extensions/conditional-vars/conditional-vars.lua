---@diagnostic disable: undefined-global
local doc_vars = {}

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

local function parse_condition(s)
  local op, val = s:match("^([><]=?)(.+)$")
  if op then return op, val end
  return nil, s
end

local function value_matches(var_val, required_val)
  if required_val:find("|", 1, true) then
    for part in required_val:gmatch("[^|]+") do
      if value_matches(var_val, part) then return true end
    end
    return false
  end
  local op, threshold = parse_condition(required_val)
  if op == nil then
    if type(var_val) == "boolean" then
      return (required_val == "true") == var_val
    end
    return tostring(var_val) == tostring(required_val)
  end
  local n_var       = tonumber(tostring(var_val))
  local n_threshold = tonumber(threshold)
  if n_var == nil or n_threshold == nil then return false end
  if op == ">"  then return n_var >  n_threshold end
  if op == ">=" then return n_var >= n_threshold end
  if op == "<"  then return n_var <  n_threshold end
  if op == "<=" then return n_var <= n_threshold end
  return false
end

local function matches(el_attrs)
  for var_name, required_val in pairs(el_attrs) do
    local var_val = doc_vars[var_name]
    if var_val == nil then
      io.stderr:write("\27[33mWARNING [conditional-vars]: unknown variable '" .. var_name .. "' referenced in .when-var / .unless-var\27[0m\n")
      return false
    end
    if not value_matches(var_val, required_val) then return false end
  end
  return true
end

local function matches_combined(el_attrs)
  for attr_name, _ in pairs(el_attrs) do
    local stripped = attr_name:match("^when%-(.+)$") or attr_name:match("^unless%-(.+)$")
    if stripped and doc_vars[stripped] == nil then
      io.stderr:write("\27[33mWARNING [conditional-vars]: unknown variable '" .. stripped .. "' referenced in .when-var / .unless-var\27[0m\n")
    end
  end
  for var_name, var_val in pairs(doc_vars) do
    local when_val = el_attrs["when-" .. var_name]
    if when_val ~= nil and not value_matches(var_val, when_val) then return false end
    local unless_val = el_attrs["unless-" .. var_name]
    if unless_val ~= nil and value_matches(var_val, unless_val) then return false end
  end
  return true
end

-- Two-pass: populate doc_vars from _variables.yml first, then filter Divs.
return {
  {
    Meta = function(_)
      doc_vars = read_project_variables()
    end
  },
  {
    Div = function(el)
      local has_when   = el.classes:includes("when-var")
      local has_unless = el.classes:includes("unless-var")
      if not has_when and not has_unless then return end

      local show
      if has_when and has_unless then
        show = matches_combined(el.attributes)
      elseif has_when then
        show = matches(el.attributes)
      else
        show = not matches(el.attributes)
      end

      return show and el.content or {}
    end
  }
}
