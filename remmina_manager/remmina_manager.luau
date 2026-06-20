-- RDP Manager launcher provider.
--
-- Usage from the launcher: `/rdp` — shows list of RDP connections.

local function getRDPConnections()
  local cmd = [[
    for f in "$HOME"/.local/share/remmina/*.remmina; do
        [ -f "$f" ] || continue
        filename=$(basename "$f")
        name=$(grep '^name=' "$f" | cut -d= -f2-)
        echo "$filename|$name"
    done
    ]]

  noctalia.runAsync(cmd, function(result)
    if result.exitCode ~= 0 then
      launcher.setResults("/rdp", {
        {
          id = "error",
          title = "Error",
          subtitle = "Failed to fetch RDP connections",
          glyph = "alert-triangle"
        }
      })
      return
    end

    local rdpRows = {}

    for _, line in ipairs(result.stdout:split("\n")) do
      if line ~= "" then
        local id, name = line:match("^([^|]+)|?(.*)$")

        table.insert(rdpRows, {
          id = id,
          title = name ~= "" and name or id,
          glyph = "device-desktop"
        })
        noctalia.notify("DEBUG", "after add str " .. name)
      end
    end

    if #rdpRows == 0 then
      launcher.setResults("/rdp", {
        {
          id = "none",
          title = "No RDP connections found",
          glyph = "info"
        }
      })
    else
      launcher.setResults("/rdp", rdpRows)
    end
  end)
end

function onQuery(query)
  if query == "/rdp" or query == "" then
    getRDPConnections()
  else
    getRDPConnections()
  end
end

local function remmina_run(id)
  local runCMD = `remmina -c ~/.local/share/remmina/{id}`
  noctalia.runAsync(runCMD)
end

function onActivate(id)
  if id == "" or id == "error" or id == "none" then return end
  remmina_run(id)
end
