-- totally by AI
-- Type definitions for lua-openssl/hmac
-- URL: https://zhaozg.github.io/lua-openssl/modules/hmac.html

local record hmac

    --- Represents the HMAC object returned by `hmac.new()`.
    -- This object is used for incremental HMAC computation.
    record HMACObject
        --- Updates the HMAC with a chunk of data.
        -- @param data (string) The data to add to the message.
        -- @return (HMACObject) Returns self to allow for method chaining.
        update: function(self: HMACObject, data: string): HMACObject

        --- Finalizes the HMAC computation and returns the digest.
        -- @param raw (boolean | nil) If true, returns the raw binary digest; otherwise, returns a hex-encoded string. Defaults to false.
        -- @return (string) The resulting HMAC digest.
        final: function(self: HMACObject, raw: boolean | nil): string

        --- Resets the HMAC object to its initial state.
        -- An optional new key can be provided.
        -- @param key (string | nil) An optional new secret key to use.
        -- @return (HMACObject) Returns self.
        reset: function(self: HMACObject, key: string | nil): HMACObject

        --- Creates a copy of the HMAC object's current state.
        -- This is useful for computing HMACs of messages that share a common prefix.
        -- @return (HMACObject) A new HMAC object.
        clone: function(self: HMACObject): HMACObject
    end

    --- Computes the HMAC digest in a single call.
    -- This is a convenience function for when the entire message is available at once.
    -- @param alg (string) The digest algorithm to use (e.g., "sha256", "md5").
    -- @param data (string) The message to be hashed.
    -- @param key (string) The secret key.
    -- @param raw (boolean | nil) If true, returns the raw binary digest; otherwise, returns a hex-encoded string. Defaults to false.
    -- @return (string) The resulting HMAC digest.
    digest: function(alg: string, data: string, key: string, raw: boolean | nil): string

    --- Creates a new HMAC object for incremental hashing.
    -- @param alg (string) The digest algorithm to use (e.g., "sha256", "md5").
    -- @param key (string) The secret key.
    -- @return (HMACObject) The new HMAC object.
    new: function(alg: string, key: string): HMACObject

end

return hmac
