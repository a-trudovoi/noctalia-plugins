-- VPN Manager launcher provider.
--
-- Usage from the launcher: `/vpn` — shows list of VPN connections.
-- Press Enter on a connection to toggle its state via `nmcli`.
-- Requires `nmcli` to be installed.

local function getVpnConnections()
  local cmd = "nmcli -t -f NAME,TYPE,STATE connection show"

  noctalia.runAsync(cmd, function(result)
    if result.exitCode ~= 0 then
      launcher.setResults("/vpn", {
        { id = "error", title = "Error", subtitle = "Failed to fetch VPN connections", glyph = "alert-triangle" }
      })
      return
    end

    local lines = result.stdout:split("\n")
    local vpnRows = {}

    for _, line in lines do
      if line ~= "" then
        -- Format is NAME:TYPE:STATE or NAME:TYPE
        local name, connType, state = line:match("([^:]+):([^:]+):?([^:]*)")

        if connType == "vpn" then
          local isActive = (state == "activated" or state == "connected")
          local glyph = isActive and "circle-key-filled" or "circle"

          table.insert(vpnRows, {
            id = name,
            title = name,
            subtitle = isActive and "Connected" or "Disconnected",
            glyph = glyph,
          })
        end
      end
    end

    if #vpnRows == 0 then
      launcher.setResults("/vpn", { { id = "none", title = "No VPN connections found", glyph = "info" } })
    else
      launcher.setResults("/vpn", vpnRows)
    end
  end)
end

function onQuery(query)
  if query == "/vpn" or query == "" then
    getVpnConnections()
  else
    getVpnConnections()
  end
end

local function vpn_toggle(id)
  local checkCmd = `nmcli -g GENERAL.STATE connection show "{id}"`

  noctalia.runAsync(checkCmd, function(result)
    if result.exitCode ~= 0 then
      noctalia.notifyError("VPN Manager", `Could not find VPN profile: {id}`)
      return
    end

    local state = result.stdout:gsub("%s+$", "")
    local isActive = state == "activated"

    local action = isActive and "down" or "up"
    local toggleCmd = `nmcli connection {action} "{id}"`

    noctalia.runAsync(toggleCmd, function(toggleResult)
      if toggleResult.exitCode == 0 then
        noctalia.notify(
          "VPN Manager",
          isActive
            and `{id} disconnected`
            or `{id} connected`
        )

        getVpnConnections()
      else
        local err = toggleResult.stderr ~= ""
          and toggleResult.stderr
          or `Failed to {action} {id}`

        noctalia.notifyError("VPN Manager", err)
      end
    end)
  end)
end

function onActivate(id)
  if id == "" or id == "error" or id == "none" then return end
  vpn_toggle(id)
end

