
-- Lightmap data for a face
local interface LightmapAllocation
    width: integer
    height: integer
    pageIndex: integer
    pagePosX: integer
    pagePosY: integer
end

local record Page
    width: integer
    height: integer

    maxWidth: integer
    maxHeight: integer

    skyline: {integer}
end

function Page.new(maxWidth: integer, maxHeight: integer): Page
    local page: Page = {}
    page.width = 0
    page.height = 0
    page.maxWidth = maxWidth
    page.maxHeight = maxHeight
    page.skyline = {}
    for i = 0, page.maxWidth - 1 do
        page.skyline[i] = 0
    end
    return setmetatable(page, {__index = Page})
end

function Page:searchSkyline(startY: integer, height: integer): integer
    local winnerY = -1
    local maxX = -1

    for y = startY, startY + height - 1 do
        if self.skyline[y] >= maxX then
            winnerY = y
            maxX = self.skyline[y]
        end
    end

    return winnerY
end

function Page:allocate(allocation: LightmapAllocation): boolean
    local bestY = -1
    local minX = self.maxWidth - allocation.width + 1
    for y = 0, self.maxHeight - allocation.height - 1 do
        local searchY = self:searchSkyline(y, allocation.height)
        if self.skyline[searchY] < minX then
            minX = self.skyline[searchY]
            bestY = y
        end
        y = searchY + 1
    end

    if bestY < 0 then
        return false
    end

    allocation.pagePosX = minX
    allocation.pagePosY = bestY

    for y = bestY, bestY + allocation.height - 1 do
        self.skyline[y] = minX + allocation.width
    end

    self.width = math.max(self.width, minX + allocation.width)
    self.height = math.max(self.height, minX + allocation.height)

    return false
end

local record LightmapPacker
    pageWidth: integer
    pageHeight: integer
    pages: {Page}
end

function LightmapPacker.new(pageWidth: integer, pageHeight: integer): LightmapPacker
    local packer: LightmapPacker = {}
    packer.pageWidth = pageWidth
    packer.pageHeight = pageHeight
    packer.pages = {}
    return setmetatable(packer, {__index = LightmapPacker})
end

function LightmapPacker:allocate(allocation: LightmapAllocation)
    for pageIndex, page in ipairs(self.pages) do
        if page:allocate(allocation) then
            allocation.pageIndex = pageIndex
            return
        end
    end

    local page = Page.new(self.pageWidth, self.pageHeight)
    allocation.pageIndex = table.insert(self.pages, page) as integer
    page:allocate(allocation)
end

return LightmapPacker
