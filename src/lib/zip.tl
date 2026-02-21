
--- https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
--- https://archive.ph/5y0w0
--- https://en.wikipedia.org/wiki/ZIP_(file_format)

local BitBuffer = require("lib.bitbuffer_sh")
local Bitflag = require("lib.bitflag")

---------------------------------------

local record FileEntry
    IDENTIFIER: string

    minimumVersion: number
    bitflag: Bitflag<any>
    compressionMethod: number
    lastModificationTime: number
    lastModificationDate: number
    uncompressedChecksum: number
    compressedSize: number
    uncompressedSize: number
    fileName: string
    extra: string

    read: function(buffer: BitBuffer): FileEntry
end

FileEntry.IDENTIFIER = "\x50\x4B\x03\x04"

function FileEntry.read(buffer: BitBuffer): FileEntry
    local this: FileEntry = {}

    local magic = buffer:Read(4)
    if magic ~= FileEntry.IDENTIFIER then
        error("invalid identifier: " .. magic)
    end

    this.minimumVersion = buffer:ReadUShort()
    this.bitflag = Bitflag.new()
    this.bitflag:set(buffer:ReadUShort())
    this.compressionMethod = buffer:ReadUShort()
    this.lastModificationTime = buffer:ReadUShort()
    this.lastModificationDate = buffer:ReadUShort()
    this.uncompressedChecksum = buffer:ReadLong()
    this.compressedSize = buffer:ReadULong()
    this.uncompressedSize = buffer:ReadULong()

    local fileNameLength = buffer:ReadUShort()
    local extraLength = buffer:ReadUShort()

    this.fileName = buffer:Read(fileNameLength)
    this.extra = buffer:Read(extraLength)

    return setmetatable(this, {__index = FileEntry})
end

---------------------------------------

local record CentralDirectoryRecord
    IDENTIFIER: string

    versionMadeBy: number
    minimumVersionToExtract: number
    bitflag: Bitflag<any>
    compressionMethod: number
    fileLastModificationTime: number
    fileLastModificationDate: number
    uncompressedChecksum: number
    compressedSize: number
    uncompressedSize: number
    fileStartDisk: number
    internalFileAttributes: number
    externalFileAttributes: number
    relativeOffsetStart: number
    fileName: string
    extra: string
    comment: string

    read: function(buffer: BitBuffer): CentralDirectoryRecord
end

CentralDirectoryRecord.IDENTIFIER = "\x50\x4B\x01\x02"

function CentralDirectoryRecord.read(buffer: BitBuffer): CentralDirectoryRecord
    local this: CentralDirectoryRecord = {}

    local magic = buffer:Read(4)
    if magic ~= CentralDirectoryRecord.IDENTIFIER then
        error("invalid identifier: " .. magic)
    end

    this.versionMadeBy = buffer:ReadUShort()
    this.minimumVersionToExtract = buffer:ReadUShort()
    this.bitflag = Bitflag.new()
    this.bitflag:set(buffer:ReadUShort())
    this.compressionMethod = buffer:ReadUShort()
    this.fileLastModificationTime = buffer:ReadUShort()
    this.fileLastModificationDate = buffer:ReadUShort()
    this.uncompressedChecksum = buffer:ReadLong()
    this.compressedSize = buffer:ReadLong()
    this.uncompressedSize = buffer:ReadLong()

    local fileNameLength = buffer:ReadUShort()
    local extraLength = buffer:ReadUShort()
    local commentLength = buffer:ReadUShort()

    this.fileStartDisk = buffer:ReadUShort()
    this.internalFileAttributes = buffer:ReadUShort()
    this.externalFileAttributes = buffer:ReadULong()
    this.relativeOffsetStart = buffer:ReadULong()

    this.fileName = buffer:Read(fileNameLength)
    this.extra = buffer:Read(extraLength)
    this.comment = buffer:Read(commentLength)

    return setmetatable(this, {__index = CentralDirectoryRecord})
end

---------------------------------------

local record EndOfCentralDirectoryRecord
    IDENTIFIER: string

    _diskNumber: number
    _centralDirectoryStartDisk: number
    _centralDirectoryRecordsOnDisk: number
    _totalCentralDirectoryRecords: number
    _centralDirectorySize: number
    _centralDirectoryOffset: number
    comment: string

    read: function(buffer: BitBuffer): EndOfCentralDirectoryRecord
end

EndOfCentralDirectoryRecord.IDENTIFIER = "\x50\x4B\x05\x06"

function EndOfCentralDirectoryRecord.read(buffer: BitBuffer): EndOfCentralDirectoryRecord
    local this: EndOfCentralDirectoryRecord = {}

    local magic = buffer:Read(4)
    if magic ~= EndOfCentralDirectoryRecord.IDENTIFIER then
        error("invalid identifier: " .. magic)
    end

    this._diskNumber = buffer:ReadShort()
    this._centralDirectoryStartDisk = buffer:ReadShort()
    this._centralDirectoryRecordsOnDisk = buffer:ReadShort()

    this._totalCentralDirectoryRecords = buffer:ReadShort()
    this._centralDirectorySize = buffer:ReadLong()
    this._centralDirectoryOffset = buffer:ReadLong()

    this.comment = buffer:ReadString()

    return setmetatable(this, {__index = EndOfCentralDirectoryRecord})
end

---------------------------------------

local record ZipFile
    fromString: function(bytes: string): ZipFile

    _buffer: BitBuffer
    _eocd: EndOfCentralDirectoryRecord

    records: {CentralDirectoryRecord}
end

function ZipFile.fromString(bytes: string): ZipFile
    local this: ZipFile = {}
    this._buffer = BitBuffer(bytes)
    this._buffer:SetLittleEndian(true)

    -- locate End of Central Directory record
    local MINIMUM_EOCD_SIZE = 22
    local searchIndex = (#bytes - MINIMUM_EOCD_SIZE) * 8
    repeat
        this._buffer:Seek(searchIndex)

        if this._buffer:Read(4) == EndOfCentralDirectoryRecord.IDENTIFIER then
            this._buffer:Skip(-32)
            break
        end

        searchIndex = searchIndex - 8
    until searchIndex < 0

    if searchIndex < 0 then
        error("unable to locate end of central directory record")
    end

    this._eocd = EndOfCentralDirectoryRecord.read(this._buffer)

    -- read central directory records
    local centralDirectoryOffset = this._eocd._centralDirectoryOffset
    this._buffer:Seek(centralDirectoryOffset * 8)

    local records = {}
    for _ = 1, this._eocd._totalCentralDirectoryRecords do
        table.insert(records, CentralDirectoryRecord.read(this._buffer))
    end
    this.records = records

    return setmetatable(this, {__index = ZipFile})
end

function ZipFile:getFileCount(): integer
    return #self.records
end

function ZipFile:getFileNames(): {string}
    local names = {}
    for _, entry in ipairs(self.records) do
        table.insert(names, entry.fileName)
    end
    return names
end

function ZipFile:getFileName(index: integer): string
    return self.records[index].fileName
end

function ZipFile:readFile(index: integer): string
    local fileRecord = self.records[index]
    self._buffer:Seek(fileRecord.relativeOffsetStart * 8)
    local fileEntry = FileEntry.read(self._buffer)
    return self._buffer:Read(fileEntry.compressedSize)
end

-- local pakConstruct = require("test.construct")
-- print("loading pak zip")
-- local zip = ZipFile.fromString(pakConstruct)
-- for _, name in ipairs(zip:getFileNames()) do
--     print(name)
-- end

-- local f = zip:readFile(1)
-- print(f)

return ZipFile
