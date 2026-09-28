-- Nova UI :: Section layer (concat-build: Nova/Util/Theme/Anim ust scope, require YOK)
-- AddToggle/AddButton/... burada TANIMLANMAZ (Init.lua baglar); AddElementCard ElementRoot dondurur.

local function GetFont(weight)
	local ok, res = pcall(function()
		return Util.GetFont(weight)
	end)
	if ok and res ~= nil then
		return res
	end
	if weight == "Bold" then
		return Enum.Font.GothamBold
	elseif weight == "Medium" then
		return Enum.Font.GothamMedium
	end
	return Enum.Font.Gotham
end

local function CreateSection(tab, title)
	title = title or "Section"
	local window = tab.Window
	local colors = window._Colors

	local Section = {
		Title = title,
		Tab = tab,
		Window = window,
		_Cards = 0,
	}

	-- Kart: radius 10, Card bg + stroke, padding 12
	local frame = Instance.new("Frame")
	frame.Name = "Section_" .. title
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundColor3 = colors.Card
	frame.BorderSizePixel = 0
	frame.LayoutOrder = #tab.Sections + 1
	frame.Parent = tab.Page
	Section.Frame = frame
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 10)
	frameCorner.Parent = frame
	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = colors.ElementBorder
	frameStroke.Transparency = 0.6
	frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	frameStroke.Parent = frame
	local framePad = Instance.new("UIPadding")
	framePad.PaddingLeft = UDim.new(0, 12)
	framePad.PaddingRight = UDim.new(0, 12)
	framePad.PaddingTop = UDim.new(0, 12)
	framePad.PaddingBottom = UDim.new(0, 12)
	framePad.Parent = frame
	local frameLayout = Instance.new("UIListLayout")
	frameLayout.FillDirection = Enum.FillDirection.Vertical
	frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
	frameLayout.Padding = UDim.new(0, 6)
	frameLayout.Parent = frame

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "SectionTitle"
	titleLbl.BackgroundTransparency = 1
	titleLbl.Size = UDim2.new(1, 0, 0, 18)
	titleLbl.LayoutOrder = 1
	titleLbl.Text = title
	titleLbl.TextSize = 13
	titleLbl.Font = GetFont("Bold")
	titleLbl.TextColor3 = colors.Text
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = frame

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.LayoutOrder = 2
	divider.BackgroundColor3 = colors.SubText
	divider.BackgroundTransparency = 0.8
	divider.BorderSizePixel = 0
	divider.Parent = frame

	function Section:AddElementCard(cardTitle, desc)
		cardTitle = cardTitle or ""
		desc = desc or ""
		self._Cards = self._Cards + 1

		local card = Instance.new("Frame")
		card.Name = "Card_" .. cardTitle
		card.Size = UDim2.new(1, 0, 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = window._Colors.Element
		card.BorderSizePixel = 0
		card.LayoutOrder = 2 + self._Cards
		card.Parent = frame
		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 7)
		cardCorner.Parent = card
		local cardPad = Instance.new("UIPadding")
		cardPad.PaddingLeft = UDim.new(0, 10)
		cardPad.PaddingRight = UDim.new(0, 10)
		cardPad.PaddingTop = UDim.new(0, 10)
		cardPad.PaddingBottom = UDim.new(0, 10)
		cardPad.Parent = card
		local cardLayout = Instance.new("UIListLayout")
		cardLayout.FillDirection = Enum.FillDirection.Vertical
		cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
		cardLayout.Padding = UDim.new(0, 6)
		cardLayout.Parent = card

		local cardTitleLbl = Instance.new("TextLabel")
		cardTitleLbl.Name = "CardTitle"
		cardTitleLbl.BackgroundTransparency = 1
		cardTitleLbl.Size = UDim2.new(1, 0, 0, 16)
		cardTitleLbl.LayoutOrder = 1
		cardTitleLbl.Text = cardTitle
		cardTitleLbl.TextSize = 13
		cardTitleLbl.Font = GetFont("Medium")
		cardTitleLbl.TextColor3 = window._Colors.Text
		cardTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
		cardTitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
		cardTitleLbl.Parent = card

		local descLbl = nil
		if desc ~= "" then
			descLbl = Instance.new("TextLabel")
			descLbl.Name = "CardDesc"
			descLbl.BackgroundTransparency = 1
			descLbl.Size = UDim2.new(1, 0, 0, 0)
			descLbl.AutomaticSize = Enum.AutomaticSize.Y
			descLbl.LayoutOrder = 2
			descLbl.Text = desc
			descLbl.TextSize = 12
			descLbl.Font = GetFont("Regular")
			descLbl.TextColor3 = window._Colors.SubText
			descLbl.TextXAlignment = Enum.TextXAlignment.Left
			descLbl.TextWrapped = true
			descLbl.Parent = card
		end

		table.insert(window.SearchIndex, { Frame = card, Title = string.lower(cardTitle) })
		table.insert(window._RefreshFns, function()
			local c = window._Colors
			card.BackgroundColor3 = c.Element
			cardTitleLbl.TextColor3 = c.Text
			if descLbl then
				descLbl.TextColor3 = c.SubText
			end
		end)

		return card
	end

	table.insert(tab.Sections, Section)
	table.insert(window._RefreshFns, function()
		local c = window._Colors
		frame.BackgroundColor3 = c.Card
		frameStroke.Color = c.ElementBorder
		titleLbl.TextColor3 = c.Text
		divider.BackgroundColor3 = c.SubText
	end)

	-- Element metodlarini bagla (Init.lua yuklendiyse; concat sirasi yuzunden pcall'li)
	pcall(function()
		if Nova._BindSection then
			Nova._BindSection(Section)
		end
	end)

	return Section
end

Nova._CreateSection = CreateSection
Nova._Section = CreateSection
