#!python
#cython: language_level=2, profile=True

import copy
import mmap
import os

class MmapByteArray(bytearray):
    """Looks like a bytearray, but from an mmap.

    Not part of public interface.
    """

    # cdef int filelength, byteoffset, bytelength
    # cdef public object filemap

    def __init__(self, source, bytelength=None, byteoffset=None):
        self.sourcename = source.name
        source.seek(0, os.SEEK_END)
        self.filelength = source.tell()
        if byteoffset is None:
            byteoffset = 0
        if bytelength is None:
            bytelength = self.filelength - byteoffset
        self.byteoffset = byteoffset
        self.bytelength = bytelength
        self.filemap = mmap.mmap(source.fileno(), 0, access=mmap.ACCESS_READ)

    def __getitem__(self, key):
        try:
            start = key.start
            stop = key.stop
        except AttributeError:
            try:
                assert 0 <= key < self.bytelength
                return ord(self.filemap[key + self.byteoffset])
            except TypeError:
                # for Python 3
                return self.filemap[key + self.byteoffset]
        else:
            if start is None:
                start = 0
            if stop is None:
                stop = self.bytelength
            assert key.step is None
            assert 0 <= start < self.bytelength
            assert 0 <= stop <= self.bytelength
            s = slice(start + self.byteoffset, stop + self.byteoffset)
            return bytearray(self.filemap.__getitem__(s))

    def __len__(self):
        return self.bytelength


cdef class ByteStore:
    """Stores raw bytes together with a bit offset and length.

    Used internally - not part of public interface.
    """

    cdef public object _rawarray
    cdef public int bitlength, offset
    cdef public bint immutable

    def __init__(self, data, bitlength=None, offset=None, immutable=False):
        """data is either a bytearray or a MmapByteArray"""
        self._rawarray = data
        if offset is None:
            offset = 0
        if bitlength is None:
            bitlength = 8 * len(data) - offset
        self.offset = offset
        self.bitlength = bitlength
        self.immutable = immutable

    def getbit(self, pos):
        assert 0 <= pos < self.bitlength
        byte, bit = divmod(self.offset + pos, 8)
        return bool(self._rawarray[byte] & (128 >> bit))

    def getbyte(self, pos):
        """Direct access to byte data."""
        return self._rawarray[pos]

    def getbyteslice(self, start, end):
        """Direct access to byte data."""
        c = self._rawarray[start:end]
        return c

    @property
    def bytelength(self):
        if not self.bitlength:
            return 0
        sb = self.offset // 8
        eb = (self.offset + self.bitlength - 1) // 8
        return eb - sb + 1

    def __copy__(self):
        return ByteStore(self._rawarray[:], self.bitlength, self.offset)

    def _appendstore(self, store):
        """Join another store on to the end of this one."""
        if not store.bitlength:
            return
        # Set new array offset to the number of bits in the final byte of current array.
        store = offsetcopy(store, (self.offset + self.bitlength) % 8)
        if store.offset:
            # first do the byte with the join.
            joinval = (self._rawarray.pop() & (255 ^ (255 >> store.offset)) |
                       (store.getbyte(0) & (255 >> store.offset)))
            self._rawarray.append(joinval)
            self._rawarray.extend(store._rawarray[1:])
        else:
            self._rawarray.extend(store._rawarray)
        self.bitlength += store.bitlength

    def _prependstore(self, store):
        """Join another store on to the start of this one."""
        if not store.bitlength:
            return
            # Set the offset of copy of store so that it's final byte
        # ends in a position that matches the offset of self,
        # then join self on to the end of it.
        store = offsetcopy(store, (self.offset - store.bitlength) % 8)
        assert (store.offset + store.bitlength) % 8 == self.offset % 8
        bit_offset = self.offset % 8
        if bit_offset:
            # first do the byte with the join.
            store.setbyte(-1, (store.getbyte(-1) & (255 ^ (255 >> bit_offset)) | \
                               (self._rawarray[self.byteoffset] & (255 >> bit_offset))))
            store._rawarray.extend(self._rawarray[self.byteoffset + 1: self.byteoffset + self.bytelength])
        else:
            store._rawarray.extend(self._rawarray[self.byteoffset: self.byteoffset + self.bytelength])
        self._rawarray = store._rawarray
        self.offset = store.offset
        self.bitlength += store.bitlength

    @property
    def byteoffset(self):
        return self.offset // 8

    @property
    def rawbytes(self):
        return self._rawarray

    def setbit(self, pos):
        assert 0 <= pos < self.bitlength
        assert self.immutable is False
        byte, bit = divmod(self.offset + pos, 8)
        self._rawarray[byte] |= (128 >> bit)

    def unsetbit(self, pos):
        assert 0 <= pos < self.bitlength
        assert self.immutable is False
        byte, bit = divmod(self.offset + pos, 8)
        self._rawarray[byte] &= ~(128 >> bit)

    def invertbit(self, pos):
        assert 0 <= pos < self.bitlength
        assert self.immutable is False
        byte, bit = divmod(self.offset + pos, 8)
        self._rawarray[byte] ^= (128 >> bit)

    def setbyte(self, pos, value):
        assert self.immutable is False
        self._rawarray[pos] = value

    def setbyteslice(self, start, end, value):
        self._rawarray[start:end] = value


def offsetcopy(s, newoffset):
    """Return a copy of a ByteStore with the newoffset.

    Not part of public interface.
    """
    assert 0 <= newoffset < 8
    if not s.bitlength:
        return copy.copy(s)
    else:
        if newoffset == s.offset % 8:
            return ByteStore(s.getbyteslice(s.byteoffset, s.byteoffset + s.bytelength), s.bitlength, newoffset)
        newdata = []
        d = s._rawarray
        assert newoffset != s.offset % 8
        if newoffset < s.offset % 8:
            # We need to shift everything left
            shiftleft = s.offset % 8 - newoffset
            # First deal with everything except for the final byte
            for x in range(s.byteoffset, s.byteoffset + s.bytelength - 1):
                newdata.append(((d[x] << shiftleft) & 0xff) +\
                               (d[x + 1] >> (8 - shiftleft)))
            bits_in_last_byte = (s.offset + s.bitlength) % 8
            if not bits_in_last_byte:
                bits_in_last_byte = 8
            if bits_in_last_byte > shiftleft:
                newdata.append((d[s.byteoffset + s.bytelength - 1] << shiftleft) & 0xff)
        else: # newoffset > s._offset % 8
            shiftright = newoffset - s.offset % 8
            newdata.append(s.getbyte(0) >> shiftright)
            for x in range(s.byteoffset + 1, s.byteoffset + s.bytelength):
                newdata.append(((d[x - 1] << (8 - shiftright)) & 0xff) +\
                               (d[x] >> shiftright))
            bits_in_last_byte = (s.offset + s.bitlength) % 8
            if not bits_in_last_byte:
                bits_in_last_byte = 8
            if bits_in_last_byte + shiftright > 8:
                newdata.append((d[s.byteoffset + s.bytelength - 1] << (8 - shiftright)) & 0xff)
        new_s = ByteStore(bytearray(newdata), s.bitlength, newoffset)
        assert new_s.offset == newoffset
        return new_s

