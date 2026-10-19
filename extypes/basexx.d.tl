-- totally by AI
-- Type definitions for basexx
-- URL: https://github.com/aiq/basexx

local record basexx

    --- ### Alphabets
    -- Pre-defined character sets for common bases.

    BASE16: string     -- "0123456789abcdef"
    BASE32: string     -- "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    BASE32HEX: string  -- "0123456789ABCDEFGHIJKLMNOPQRSTUV"
    BASE36: string     -- "0123456789abcdefghijklmnopqrstuvwxyz"
    BASE58: string     -- "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    BASE62: string     -- "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" (Default)
    BASE64: string     -- "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    --- ### Functions

    --- Encodes an arbitrary-precision integer into a base-XX string.
    -- @param num (integer | string) The number to encode. Can be a Lua integer or a string for very large numbers.
    -- @param alpha (string | nil) The alphabet to use for encoding. Defaults to BASE62 if nil.
    -- @return (string) The resulting base-XX encoded string.
    to_xx: function(num: integer | string, alpha: string | nil): string

    --- Decodes a base-XX string back into an arbitrary-precision integer.
    -- @param str (string) The base-XX encoded string to decode.
    -- @param alpha (string | nil) The alphabet used for decoding. Defaults to BASE62 if nil.
    -- @return (string) The decoded number, returned as a string to handle arbitrary precision.
    from_xx: function(str: string, alpha: string | nil): string

end

return basexx

