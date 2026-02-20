local record BitBuffer
    metamethod __call: function(_: BitBuffer, string, littleEndian?: boolean): BitBuffer

    FromNet: function(bits: number): BitBuffer
    ToNet: function(self): number
    ReadFromNet: function(self, bits: number): self
    WriteToNet: function(self): number

    Tell: function(self): number
    Seek: function(self, number): self
    Skip: function(self, number): self
    Clear: function(self): boolean
    EndOfData: function(self): boolean
    IsLittleEndian: function(self): boolean
    IsBigEndian: function(self): boolean
    SetLittleEndian: function(self, boolean): self
    SetBigEndian: function(self, boolean): self

    Read: function(self, count: number): string

    WriteUInt: function(self, value: number, bits: number): self
    ReadUInt: function(self, bits: number): number
    WriteInt: function(self, value: number, bits: number): self
    ReadInt: function(self, bits: number): number

    WriteLong: function(self, value: number): self
    ReadLong: function(self): number
    WriteShort: function(self, value: number): self
    ReadShort: function(self): number
    WriteSignedByte: function(self, value: number): self
    ReadSignedByte: function(self): number
    WriteULong: function(self, value: number): self
    ReadULong: function(self): number
    WriteUShort: function(self, value: number): self
    ReadUShort: function(self): number
    WriteByte: function(self, value: number): self
    ReadByte: function(self): number
    WriteNibble: function(self, value: number): self
    ReadNibble: function(self): number
    WriteSnort: function(self, value: number): self
    ReadSnort: function(self): number

    WriteFloat: function(self, value: number): self
    ReadFloat: function(self): number
    WriteDouble: function(self, value: number): self
    ReadDouble: function(self): number

    WriteBoolean: function(self, value: boolean): self
    ReadBoolean: function(self): boolean
    WriteVector: function(self, value: GVector): self
    ReadVector: function(self): GVector
    WriteString: function(self, value: string): self
    ReadString: function(self): string
    WriteAngle: function(self, value: GAngle): self
    ReadAngle: function(self): GAngle
    WriteColor: function(self, value: GColor): self
    ReadColor: function(self): GColor
    WriteTable: function(self, value: table): self
    ReadTable: function(self): table
    WriteType: function(self, value: any): self
    ReadType: function(self): E_TYPE
    WriteStringNull: function(self, value: string): self
    ReadStringNull: function(self, maxLength?: number): string
end

return BitBuffer
