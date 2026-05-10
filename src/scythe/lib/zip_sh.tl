--- https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
--- https://archive.ph/5y0w0
--- https://en.wikipedia.org/wiki/ZIP_(file_format)

local ByteReader = require("scythe.lib.byte_reader_sh")
local Bitflag = require("scythe.lib.bitflag_sh")

---------------------------------------

local record FileEntry
    IDENTIFIER: string

    minimumVersion: integer
    bitflag: Bitflag<any>
    compressionMethod: number
    lastModificationTime: number
    lastModificationDate: number
    uncompressedChecksum: integer
    compressedSize: integer
    uncompressedSize: integer
    fileName: string
    extra: string

    read: function(buffer: ByteReader): FileEntry
end

FileEntry.IDENTIFIER = "\x50\x4B\x03\x04"

function FileEntry.read(buffer: ByteReader): FileEntry
    local this: FileEntry = {}

    local magic = buffer:read(4)
    if magic ~= FileEntry.IDENTIFIER then
        error("invalid identifier: " .. magic)
    end

    this.minimumVersion = buffer:readU16LE()
    this.bitflag = Bitflag.new()
    this.bitflag:set(buffer:readU16LE())
    this.compressionMethod = buffer:readU16LE()
    this.lastModificationTime = buffer:readU16LE()
    this.lastModificationDate = buffer:readU16LE()
    this.uncompressedChecksum = buffer:readS32LE()
    this.compressedSize = buffer:readU32LE()
    this.uncompressedSize = buffer:readU32LE()

    local fileNameLength = buffer:readU16LE()
    local extraLength = buffer:readU16LE()

    this.fileName = buffer:read(fileNameLength)
    this.extra = buffer:read(extraLength)

    return setmetatable(this, {__index = FileEntry})
end

---------------------------------------

local record CentralDirectoryRecord
    IDENTIFIER: string

    versionMadeBy: integer
    minimumVersionToExtract: integer
    bitflag: Bitflag<any>
    compressionMethod: number
    fileLastModificationTime: number
    fileLastModificationDate: number
    uncompressedChecksum: integer
    compressedSize: integer
    uncompressedSize: integer
    fileStartDisk: integer
    internalFileAttributes: number
    externalFileAttributes: number
    relativeOffsetStart: integer
    fileName: string
    extra: string
    comment: string

    read: function(buffer: ByteReader): CentralDirectoryRecord
end

CentralDirectoryRecord.IDENTIFIER = "\x50\x4B\x01\x02"

function CentralDirectoryRecord.read(buffer: ByteReader): CentralDirectoryRecord
    local this: CentralDirectoryRecord = {}

    local magic = buffer:read(4)
    if magic ~= CentralDirectoryRecord.IDENTIFIER then
        error("invalid identifier: " .. magic)
    end

    this.versionMadeBy = buffer:readU16LE()
    this.minimumVersionToExtract = buffer:readU16LE()
    this.bitflag = Bitflag.new()
    this.bitflag:set(buffer:readU16LE())
    this.compressionMethod = buffer:readU16LE()
    this.fileLastModificationTime = buffer:readU16LE()
    this.fileLastModificationDate = buffer:readU16LE()
    this.uncompressedChecksum = buffer:readS32LE()
    this.compressedSize = buffer:readS32LE()
    this.uncompressedSize = buffer:readS32LE()

    local fileNameLength = buffer:readU16LE()
    local extraLength = buffer:readU16LE()
    local commentLength = buffer:readU16LE()

    this.fileStartDisk = buffer:readU16LE()
    this.internalFileAttributes = buffer:readU16LE()
    this.externalFileAttributes = buffer:readU32LE()
    this.relativeOffsetStart = buffer:readU32LE()

    this.fileName = buffer:read(fileNameLength)
    this.extra = buffer:read(extraLength)
    this.comment = buffer:read(commentLength)

    return setmetatable(this, {__index = CentralDirectoryRecord})
end

---------------------------------------

local record EndOfCentralDirectoryRecord
    IDENTIFIER: string

    _diskNumber: integer
    _centralDirectoryStartDisk: integer
    _centralDirectoryRecordsOnDisk: integer
    _totalCentralDirectoryRecords: integer
    _centralDirectorySize: integer
    _centralDirectoryOffset: integer
    comment: string

    read: function(buffer: ByteReader): EndOfCentralDirectoryRecord
end

EndOfCentralDirectoryRecord.IDENTIFIER = "\x50\x4B\x05\x06"

function EndOfCentralDirectoryRecord.read(buffer: ByteReader): EndOfCentralDirectoryRecord
    local this: EndOfCentralDirectoryRecord = {}

    local magic = buffer:read(4)
    if magic ~= EndOfCentralDirectoryRecord.IDENTIFIER then
        error("invalid identifier: " .. magic)
    end

    this._diskNumber = buffer:readS16LE()
    this._centralDirectoryStartDisk = buffer:readS16LE()
    this._centralDirectoryRecordsOnDisk = buffer:readS16LE()

    this._totalCentralDirectoryRecords = buffer:readS16LE()
    this._centralDirectorySize = buffer:readS32LE()
    this._centralDirectoryOffset = buffer:readS32LE()

    this.comment = buffer:read(buffer:readU16LE())

    return setmetatable(this, {__index = EndOfCentralDirectoryRecord})
end

---------------------------------------

local record ZipFile
    fromString: function(bytes: string): ZipFile

    _buffer: ByteReader
    _eocd: EndOfCentralDirectoryRecord

    records: {CentralDirectoryRecord}
end

function ZipFile.fromString(bytes: string): ZipFile
    local this: ZipFile = {}
    this._buffer = ByteReader.new(bytes)

    -- locate End of Central Directory record
    local MINIMUM_EOCD_SIZE = 22
    local searchIndex = (#bytes - MINIMUM_EOCD_SIZE)
    repeat
        this._buffer:seek(searchIndex)

        if this._buffer:read(4) == EndOfCentralDirectoryRecord.IDENTIFIER then
            this._buffer:skip(-4)
            break
        end

        searchIndex = searchIndex - 1
    until searchIndex < 0

    if searchIndex < 0 then
        error("unable to locate end of central directory record")
    end

    this._eocd = EndOfCentralDirectoryRecord.read(this._buffer)

    -- read central directory records
    local centralDirectoryOffset = this._eocd._centralDirectoryOffset
    this._buffer:seek(centralDirectoryOffset)

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
    self._buffer:seek(fileRecord.relativeOffsetStart)
    local fileEntry = FileEntry.read(self._buffer)
    return self._buffer:read(fileEntry.compressedSize)
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
