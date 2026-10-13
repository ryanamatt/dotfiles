-- Matugen colorscheme engine for Neovim.
--
-- Reads the palette that matugen renders into lua/matugen_palette.lua and
-- turns it into highlight groups. The palette is the only generated file;
-- everything in here is plain Lua so matugen never has to parse it.
--
-- Options (set before :colorscheme matugen):
--   vim.g.matugen_transparent = false   -- opaque background (default: true)
--
-- Commands:
--   :MatugenTransparent   toggle the transparent background
--   :MatugenReload        re-read the palette and re-apply the theme

local M = {}

-- Used when matugen has not generated a palette yet (first launch, fresh
-- clone). These are the seed colors from config.toml plus a neutral purple
-- Material You dark scheme, so Neovim is never left unstyled.
local fallback = {
  bg = "#141318", surface_lowest = "#0f0d13", surface_low = "#1c1b20",
  surface = "#201f25", surface_high = "#2b292f", surface_highest = "#36343a",
  fg = "#e6e1e9", fg_muted = "#cac4d0", outline = "#948f99", outline_variant = "#49454f",
  primary = "#cfbcff", on_primary = "#381e72", primary_container = "#4f378a", on_primary_container = "#e9ddff",
  secondary = "#ccc2dc", on_secondary = "#332d41", secondary_container = "#4a4458", on_secondary_container = "#e8def8",
  tertiary = "#efb8c8", on_tertiary = "#492532", tertiary_container = "#633b48", on_tertiary_container = "#ffd8e4",
  error = "#ffb4ab", on_error = "#690005", error_container = "#93000a", on_error_container = "#ffdad6",
  success = "#6fbf73", warning = "#c9a24a", info = "#a8d8e0", ember = "#d9884a",
  purple = "#9c6ade", blue = "#4a90d9", cyan = "#4dd0e1", teal = "#26a69a",
  green = "#5cb85c", lime = "#b0d94e", yellow = "#e6c34d", orange = "#e2984a",
  red = "#d9534f", pink = "#e07fa8", magenta = "#c454c4", indigo = "#6272c4",
}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function rgb(hex)
  hex = hex:gsub("^#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

-- Mix `top` over `base`. alpha is the weight of `top` (0 to 1).
local function blend(top, base, alpha)
  local tr, tg, tb = rgb(top)
  local br, bg, bb = rgb(base)
  local function mix(t, b)
    return math.floor(t * alpha + b * (1 - alpha) + 0.5)
  end
  return string.format("#%02x%02x%02x", mix(tr, br), mix(tg, bg), mix(tb, bb))
end

local function luminance(hex)
  local r, g, b = rgb(hex)
  return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
end

local cache

--- Load the generated palette (missing keys fall back to defaults).
function M.palette(reload)
  if reload or not cache then
    package.loaded["matugen_palette"] = nil
    local ok, mod = pcall(require, "matugen_palette")
    cache = setmetatable(ok and type(mod) == "table" and mod or {}, { __index = fallback })
  end
  return cache
end

function M.transparent()
  return vim.g.matugen_transparent ~= false
end

---------------------------------------------------------------------------
-- Lualine theme
---------------------------------------------------------------------------

function M.lualine_theme()
  local p = M.palette()
  local mid = M.transparent() and "NONE" or p.surface_low

  local function mode(accent)
    return {
      a = { fg = p.bg, bg = accent, gui = "bold" },
      b = { fg = p.fg, bg = p.surface_high },
      c = { fg = p.fg_muted, bg = mid },
    }
  end

  return {
    normal = mode(p.primary),
    insert = mode(p.success),
    visual = mode(p.tertiary),
    replace = mode(p.error),
    command = mode(p.warning),
    terminal = mode(p.teal),
    inactive = {
      a = { fg = p.outline, bg = mid },
      b = { fg = p.outline, bg = mid },
      c = { fg = p.outline, bg = mid },
    },
  }
end

---------------------------------------------------------------------------
-- Highlight groups
---------------------------------------------------------------------------

function M.apply(p, transparent)
  local NONE = "NONE"

  local function hl(group, spec)
    if type(spec) == "string" then
      spec = { link = spec }
    end
    vim.api.nvim_set_hl(0, group, spec)
  end

  -- Derived colors
  local base = transparent and NONE or p.bg
  local side = transparent and NONE or p.surface_lowest
  local bar = transparent and NONE or p.surface_low
  local float = p.surface_low
  local border = blend(p.primary, float, 0.55)
  local cursorline = blend(p.primary, p.bg, 0.07)
  local faint = blend(p.outline, p.bg, 0.55)

  -- Syntax roles. Change these to re-theme every language at once.
  local syn = {
    keyword = p.primary,
    import = p.purple,
    func = p.blue,
    builtin_func = p.cyan,
    string = p.green,
    number = p.orange,
    constant = p.orange,
    type = p.yellow,
    operator = p.cyan,
    property = p.teal,
    param = p.ember,
    special = p.magenta,
    self = p.red,
    module = p.indigo,
    punct = p.fg_muted,
    comment = p.outline,
  }

  -- Editor ---------------------------------------------------------------
  hl("Normal", { fg = p.fg, bg = base })
  hl("NormalNC", "Normal")
  hl("NormalFloat", { fg = p.fg, bg = float })
  hl("FloatBorder", { fg = border, bg = float })
  hl("FloatTitle", { fg = p.primary, bg = float, bold = true })
  hl("FloatFooter", { fg = p.outline, bg = float })

  hl("Cursor", { fg = p.bg, bg = p.secondary })
  hl("lCursor", "Cursor")
  hl("CursorIM", "Cursor")
  hl("TermCursor", "Cursor")
  hl("CursorLine", { bg = cursorline })
  hl("CursorColumn", "CursorLine")
  hl("ColorColumn", { bg = p.surface_low })
  hl("CursorLineNr", { fg = p.primary, bold = true })
  hl("LineNr", { fg = faint })
  hl("LineNrAbove", "LineNr")
  hl("LineNrBelow", "LineNr")
  hl("SignColumn", { fg = faint, bg = NONE })
  hl("FoldColumn", { fg = faint, bg = NONE })
  hl("Folded", { fg = p.fg_muted, bg = p.surface_low })
  hl("EndOfBuffer", { fg = p.bg })
  hl("NonText", { fg = faint })
  hl("Whitespace", { fg = faint })
  hl("SpecialKey", { fg = faint })
  hl("Conceal", { fg = p.outline })

  hl("Visual", { bg = p.primary_container })
  hl("VisualNOS", "Visual")
  hl("Search", { fg = p.on_tertiary_container, bg = p.tertiary_container })
  hl("CurSearch", { fg = p.on_tertiary, bg = p.tertiary, bold = true })
  hl("IncSearch", "CurSearch")
  hl("Substitute", { fg = p.on_error, bg = p.error })
  hl("MatchParen", { fg = p.tertiary, bg = p.surface_highest, bold = true })

  hl("WinSeparator", { fg = p.outline_variant, bg = NONE })
  hl("VertSplit", "WinSeparator")
  hl("StatusLine", { fg = p.fg_muted, bg = bar })
  hl("StatusLineNC", { fg = p.outline, bg = bar })
  hl("WinBar", "StatusLine")
  hl("WinBarNC", "StatusLineNC")
  hl("TabLine", { fg = p.outline, bg = p.surface_low })
  hl("TabLineFill", { bg = side })
  hl("TabLineSel", { fg = p.bg, bg = p.primary, bold = true })

  hl("Pmenu", { fg = p.fg, bg = p.surface_high })
  hl("PmenuSel", { fg = p.on_primary_container, bg = p.primary_container })
  hl("PmenuSbar", { bg = p.surface_highest })
  hl("PmenuThumb", { bg = p.outline })
  hl("WildMenu", "PmenuSel")

  hl("Directory", { fg = p.blue })
  hl("Title", { fg = p.primary, bold = true })
  hl("ErrorMsg", { fg = p.error })
  hl("WarningMsg", { fg = p.warning })
  hl("ModeMsg", { fg = p.fg_muted, bold = true })
  hl("MoreMsg", { fg = p.success })
  hl("Question", { fg = p.info })
  hl("QuickFixLine", { bg = p.surface_high, bold = true })

  hl("SpellBad", { undercurl = true, sp = p.error })
  hl("SpellCap", { undercurl = true, sp = p.warning })
  hl("SpellRare", { undercurl = true, sp = p.info })
  hl("SpellLocal", { undercurl = true, sp = p.teal })

  -- Diff -----------------------------------------------------------------
  hl("DiffAdd", { bg = blend(p.success, p.bg, 0.18) })
  hl("DiffChange", { bg = blend(p.blue, p.bg, 0.16) })
  hl("DiffDelete", { bg = blend(p.error, p.bg, 0.18) })
  hl("DiffText", { bg = blend(p.blue, p.bg, 0.34) })
  hl("Added", { fg = p.success })
  hl("Changed", { fg = p.blue })
  hl("Removed", { fg = p.error })

  -- Vim syntax -----------------------------------------------------------
  hl("Comment", { fg = syn.comment, italic = true })
  hl("Constant", { fg = syn.constant })
  hl("String", { fg = syn.string })
  hl("Character", { fg = syn.string })
  hl("Number", { fg = syn.number })
  hl("Boolean", { fg = syn.number })
  hl("Float", "Number")
  hl("Identifier", { fg = p.fg })
  hl("Function", { fg = syn.func })
  hl("Statement", { fg = syn.keyword })
  hl("Conditional", "Statement")
  hl("Repeat", "Statement")
  hl("Label", "Statement")
  hl("Keyword", "Statement")
  hl("Exception", "Statement")
  hl("Operator", { fg = syn.operator })
  hl("PreProc", { fg = syn.import })
  hl("Include", "PreProc")
  hl("Define", "PreProc")
  hl("Macro", "PreProc")
  hl("PreCondit", "PreProc")
  hl("Type", { fg = syn.type })
  hl("StorageClass", "Type")
  hl("Structure", "Type")
  hl("Typedef", "Type")
  hl("Special", { fg = syn.special })
  hl("SpecialChar", "Special")
  hl("Tag", "Special")
  hl("Delimiter", { fg = syn.punct })
  hl("SpecialComment", { fg = syn.comment, bold = true })
  hl("Debug", "Special")
  hl("Underlined", { fg = p.tertiary, underline = true })
  hl("Ignore", { fg = p.outline })
  hl("Error", { fg = p.error })
  hl("Todo", { fg = p.bg, bg = p.info, bold = true })

  -- Treesitter -----------------------------------------------------------
  hl("@variable", { fg = p.fg })
  hl("@variable.builtin", { fg = syn.self })
  hl("@variable.parameter", { fg = syn.param })
  hl("@variable.member", { fg = syn.property })
  hl("@property", { fg = syn.property })
  hl("@field", { fg = syn.property })
  hl("@parameter", { fg = syn.param })
  hl("@constant", { fg = syn.constant })
  hl("@constant.builtin", { fg = syn.constant })
  hl("@module", { fg = syn.module })
  hl("@namespace", { fg = syn.module })
  hl("@label", { fg = syn.keyword })

  hl("@string", { fg = syn.string })
  hl("@string.escape", { fg = syn.special })
  hl("@string.regexp", { fg = syn.special })
  hl("@string.special.url", { fg = p.info, underline = true })
  hl("@character", { fg = syn.string })
  hl("@number", { fg = syn.number })
  hl("@boolean", { fg = syn.number })

  hl("@function", { fg = syn.func })
  hl("@function.call", { fg = syn.func })
  hl("@function.builtin", { fg = syn.builtin_func })
  hl("@function.macro", { fg = syn.import })
  hl("@method", { fg = syn.func })
  hl("@method.call", { fg = syn.func })
  hl("@constructor", { fg = syn.type })

  hl("@type", { fg = syn.type })
  hl("@type.builtin", { fg = syn.type })
  hl("@attribute", { fg = syn.import })

  hl("@keyword", { fg = syn.keyword })
  hl("@keyword.import", { fg = syn.import })
  hl("@include", { fg = syn.import })
  hl("@operator", { fg = syn.operator })
  hl("@punctuation.delimiter", { fg = syn.punct })
  hl("@punctuation.bracket", { fg = syn.punct })
  hl("@punctuation.special", { fg = syn.operator })

  hl("@comment", "Comment")
  hl("@comment.error", { fg = p.error, bold = true })
  hl("@comment.warning", { fg = p.warning, bold = true })
  hl("@comment.note", { fg = p.info, bold = true })
  hl("@comment.todo", { fg = p.bg, bg = p.info, bold = true })

  hl("@tag", { fg = syn.self })
  hl("@tag.attribute", { fg = syn.param })
  hl("@tag.delimiter", { fg = syn.punct })

  hl("@markup.heading", { fg = p.primary, bold = true })
  hl("@markup.heading.1", { fg = p.primary, bold = true })
  hl("@markup.heading.2", { fg = p.tertiary, bold = true })
  hl("@markup.heading.3", { fg = p.blue, bold = true })
  hl("@markup.heading.4", { fg = p.teal, bold = true })
  hl("@markup.heading.5", { fg = p.green, bold = true })
  hl("@markup.heading.6", { fg = p.yellow, bold = true })
  hl("@markup.strong", { bold = true })
  hl("@markup.italic", { italic = true })
  hl("@markup.strikethrough", { strikethrough = true })
  hl("@markup.underline", { underline = true })
  hl("@markup.link", { fg = p.tertiary })
  hl("@markup.link.url", { fg = p.info, underline = true })
  hl("@markup.raw", { fg = p.teal })
  hl("@markup.list", { fg = p.primary })
  hl("@markup.quote", { fg = p.fg_muted, italic = true })
  hl("@diff.plus", { fg = p.success })
  hl("@diff.minus", { fg = p.error })
  hl("@diff.delta", { fg = p.blue })

  -- LSP semantic tokens
  hl("@lsp.type.comment", {})
  hl("@lsp.type.macro", "@function.macro")
  hl("@lsp.type.parameter", "@variable.parameter")
  hl("@lsp.type.property", "@property")
  hl("@lsp.type.enumMember", "@constant")

  -- Diagnostics and LSP --------------------------------------------------
  local diag = {
    Error = p.error,
    Warn = p.warning,
    Info = p.info,
    Hint = p.teal,
    Ok = p.success,
  }
  for name, color in pairs(diag) do
    hl("Diagnostic" .. name, { fg = color })
    hl("DiagnosticVirtualText" .. name, { fg = color, bg = blend(color, p.bg, 0.12) })
    hl("DiagnosticUnderline" .. name, { undercurl = true, sp = color })
  end

  hl("LspReferenceText", { bg = p.surface_highest })
  hl("LspReferenceRead", { bg = p.surface_highest })
  hl("LspReferenceWrite", { bg = p.surface_highest, underline = true })
  hl("LspInlayHint", { fg = p.outline, bg = blend(p.outline, p.bg, 0.12) })
  hl("LspCodeLens", { fg = p.outline })
  hl("LspSignatureActiveParameter", { fg = p.tertiary, bold = true, underline = true })

  -- Telescope ------------------------------------------------------------
  hl("TelescopeNormal", "NormalFloat")
  hl("TelescopeBorder", "FloatBorder")
  hl("TelescopeTitle", { fg = p.primary, bold = true })
  hl("TelescopePromptNormal", { fg = p.fg, bg = p.surface_high })
  hl("TelescopePromptBorder", { fg = p.surface_high, bg = p.surface_high })
  hl("TelescopePromptTitle", { fg = p.on_primary, bg = p.primary, bold = true })
  hl("TelescopePromptPrefix", { fg = p.primary })
  hl("TelescopeResultsTitle", { fg = p.fg_muted })
  hl("TelescopePreviewTitle", { fg = p.on_tertiary, bg = p.tertiary, bold = true })
  hl("TelescopeSelection", { fg = p.on_primary_container, bg = p.primary_container })
  hl("TelescopeSelectionCaret", { fg = p.primary, bg = p.primary_container })
  hl("TelescopeMatching", { fg = p.tertiary, bold = true })
  hl("TelescopeMultiSelection", { fg = p.warning })

  -- Neo-tree -------------------------------------------------------------
  hl("NeoTreeNormal", { fg = p.fg, bg = side })
  hl("NeoTreeNormalNC", { fg = p.fg, bg = side })
  hl("NeoTreeEndOfBuffer", { fg = side == NONE and p.bg or side, bg = side })
  hl("NeoTreeWinSeparator", { fg = p.outline_variant, bg = side })
  hl("NeoTreeRootName", { fg = p.primary, bold = true })
  hl("NeoTreeDirectoryName", { fg = p.blue })
  hl("NeoTreeDirectoryIcon", { fg = p.blue })
  hl("NeoTreeFileName", { fg = p.fg })
  hl("NeoTreeFileNameOpened", { fg = p.primary })
  hl("NeoTreeDimText", { fg = p.outline })
  hl("NeoTreeDotfile", { fg = p.fg_muted })
  hl("NeoTreeIndentMarker", { fg = p.outline_variant })
  hl("NeoTreeExpander", { fg = p.outline })
  hl("NeoTreeCursorLine", { bg = p.surface_high })
  hl("NeoTreeTitleBar", { fg = p.on_primary, bg = p.primary, bold = true })
  hl("NeoTreeFloatBorder", "FloatBorder")
  hl("NeoTreeFloatTitle", "FloatTitle")
  hl("NeoTreeGitAdded", { fg = p.success })
  hl("NeoTreeGitModified", { fg = p.warning })
  hl("NeoTreeGitDeleted", { fg = p.error })
  hl("NeoTreeGitRenamed", { fg = p.blue })
  hl("NeoTreeGitUntracked", { fg = p.teal })
  hl("NeoTreeGitIgnored", { fg = p.outline })
  hl("NeoTreeGitConflict", { fg = p.red, bold = true })
  hl("NeoTreeGitStaged", { fg = p.success })
  hl("NeoTreeGitUnstaged", { fg = p.warning })

  -- Gitsigns -------------------------------------------------------------
  hl("GitSignsAdd", { fg = p.success })
  hl("GitSignsChange", { fg = p.blue })
  hl("GitSignsDelete", { fg = p.error })
  hl("GitSignsTopdelete", { fg = p.error })
  hl("GitSignsChangedelete", { fg = p.warning })
  hl("GitSignsUntracked", { fg = p.teal })
  hl("GitSignsCurrentLineBlame", { fg = p.outline, italic = true })

  -- Indent guides --------------------------------------------------------
  hl("IblIndent", { fg = p.outline_variant, nocombine = true })
  hl("IblWhitespace", { fg = p.outline_variant, nocombine = true })
  hl("IblScope", { fg = p.primary, nocombine = true })

  -- Which-key ------------------------------------------------------------
  hl("WhichKey", { fg = p.primary })
  hl("WhichKeyGroup", { fg = p.blue })
  hl("WhichKeyDesc", { fg = p.fg })
  hl("WhichKeySeparator", { fg = p.outline })
  hl("WhichKeyValue", { fg = p.outline })
  hl("WhichKeyIcon", { fg = p.blue })
  hl("WhichKeyNormal", "NormalFloat")
  hl("WhichKeyBorder", "FloatBorder")
  hl("WhichKeyTitle", "FloatTitle")

  -- Trouble --------------------------------------------------------------
  hl("TroubleNormal", { fg = p.fg, bg = side })
  hl("TroubleNormalNC", { fg = p.fg, bg = side })
  hl("TroubleText", { fg = p.fg })
  hl("TroubleCount", { fg = p.on_tertiary, bg = p.tertiary, bold = true })
  hl("TroubleCode", { fg = p.outline })
  hl("TroubleSource", { fg = p.outline })
  hl("TroublePos", { fg = p.outline })
  hl("TroubleIndent", { fg = p.outline_variant })
  hl("TroublePreview", { bg = p.surface_highest })

  -- blink.cmp ------------------------------------------------------------
  hl("BlinkCmpMenu", { fg = p.fg, bg = p.surface_high })
  hl("BlinkCmpMenuBorder", { fg = border, bg = p.surface_high })
  hl("BlinkCmpMenuSelection", { fg = p.on_primary_container, bg = p.primary_container })
  hl("BlinkCmpScrollBarThumb", { bg = p.outline })
  hl("BlinkCmpScrollBarGutter", { bg = p.surface_highest })
  hl("BlinkCmpLabel", { fg = p.fg })
  hl("BlinkCmpLabelDeprecated", { fg = p.outline, strikethrough = true })
  hl("BlinkCmpLabelMatch", { fg = p.primary, bold = true })
  hl("BlinkCmpLabelDetail", { fg = p.outline })
  hl("BlinkCmpLabelDescription", { fg = p.outline })
  hl("BlinkCmpSource", { fg = p.outline })
  hl("BlinkCmpGhostText", { fg = p.outline })
  hl("BlinkCmpDoc", "NormalFloat")
  hl("BlinkCmpDocBorder", "FloatBorder")
  hl("BlinkCmpDocSeparator", { fg = p.outline_variant, bg = float })
  hl("BlinkCmpSignatureHelp", "NormalFloat")
  hl("BlinkCmpSignatureHelpBorder", "FloatBorder")
  hl("BlinkCmpSignatureHelpActiveParameter", "LspSignatureActiveParameter")

  local kinds = {
    Text = p.fg_muted, Method = p.blue, Function = p.blue, Constructor = p.yellow,
    Field = p.teal, Variable = p.fg, Class = p.yellow, Interface = p.yellow,
    Module = p.indigo, Property = p.teal, Unit = p.orange, Value = p.orange,
    Enum = p.yellow, Keyword = p.primary, Snippet = p.pink, Color = p.magenta,
    File = p.fg_muted, Reference = p.fg_muted, Folder = p.blue, EnumMember = p.orange,
    Constant = p.orange, Struct = p.yellow, Event = p.magenta, Operator = p.cyan,
    TypeParameter = p.yellow,
  }
  hl("BlinkCmpKind", { fg = p.fg_muted })
  for kind, color in pairs(kinds) do
    hl("BlinkCmpKind" .. kind, { fg = color })
  end

  -- Dashboard ------------------------------------------------------------
  hl("DashboardHeader", { fg = p.primary, bold = true })
  hl("DashboardIcon", { fg = p.cyan })
  hl("DashboardDesc", { fg = p.fg })
  hl("DashboardKey", { fg = p.orange, bold = true })
  hl("DashboardShortCut", { fg = p.orange, bold = true })
  hl("DashboardProjectTitle", { fg = p.purple, bold = true })
  hl("DashboardProjectTitleIcon", { fg = p.purple })
  hl("DashboardProjectIcon", { fg = p.cyan })
  hl("DashboardMruTitle", { fg = p.green, bold = true })
  hl("DashboardMruIcon", { fg = p.green })
  hl("DashboardFiles", { fg = p.fg })
  hl("DashboardFooter", { fg = p.outline, italic = true })

  -- Lazy and Mason -------------------------------------------------------
  hl("LazyH1", { fg = p.on_primary, bg = p.primary, bold = true })
  hl("LazyButton", { fg = p.fg, bg = p.surface_high })
  hl("LazyButtonActive", { fg = p.on_primary_container, bg = p.primary_container, bold = true })
  hl("LazySpecial", { fg = p.primary })
  hl("MasonHeader", { fg = p.on_primary, bg = p.primary, bold = true })
  hl("MasonHighlight", { fg = p.primary })
  hl("MasonHighlightBlock", { fg = p.on_primary, bg = p.primary })
  hl("MasonHighlightBlockBold", { fg = p.on_primary, bg = p.primary, bold = true })
  hl("MasonMuted", { fg = p.outline })
  hl("MasonMutedBlock", { fg = p.fg_muted, bg = p.surface_highest })

  -- Terminal palette (mirrors the kitty template) ------------------------
  local function lighten(color)
    return blend("#ffffff", color, 0.12)
  end
  local term = {
    p.bg, p.error, p.success, p.warning, p.secondary, p.primary, p.info, p.fg_muted,
    p.surface_high, lighten(p.error), lighten(p.success), lighten(p.warning),
    lighten(p.secondary), lighten(p.primary), lighten(p.info), p.fg,
  }
  for i, color in ipairs(term) do
    vim.g["terminal_color_" .. (i - 1)] = color
  end
end

---------------------------------------------------------------------------
-- Entry point (called from colors/matugen.lua)
---------------------------------------------------------------------------

function M.load()
  local p = M.palette(true)

  if vim.g.colors_name then
    vim.cmd("hi clear")
  end
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.o.termguicolors = true

  -- Set 'background' with colors_name cleared, otherwise Neovim re-sources
  -- the colorscheme and we would recurse.
  vim.g.colors_name = nil
  local want = luminance(p.bg) > 0.5 and "light" or "dark"
  if vim.o.background ~= want then
    vim.o.background = want
  end
  vim.g.colors_name = "matugen"

  M.apply(p, M.transparent())

  vim.api.nvim_create_user_command("MatugenTransparent", function()
    vim.g.matugen_transparent = not M.transparent()
    vim.cmd.colorscheme("matugen")
  end, { desc = "Toggle transparent background" })

  vim.api.nvim_create_user_command("MatugenReload", function()
    vim.cmd.colorscheme("matugen")
  end, { desc = "Re-read the matugen palette" })
end

return M
