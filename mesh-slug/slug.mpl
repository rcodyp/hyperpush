# Slug module — URL-safe slug generation for Mesh.
#
# API:
#   Slug.slugify(str)               -> String  (default separator: "-")
#   Slug.slugify_with_sep(str, sep) -> String  (custom separator)
#   Slug.truncate(slug, max)        -> String  (cut at last separator boundary)
#   Slug.is_valid(slug)             -> Bool    (true if already a valid slug)
#
# NOTE: Mesh's module export system uses name-only keys (FxHashMap<String, Scheme>),
# so two pub fns with the same name but different arity cannot both be exported.
# slugify/2 is therefore named slugify_with_sep/2. Plan 02 tests reference this name.

# Convert a string to a URL-safe slug using the default "-" separator.
# Lowercases, replaces non-alphanumeric chars with separator, collapses
# consecutive separators, and strips leading/trailing separators.
pub fn slugify(str :: String) -> String do
  ""
end

# Convert a string to a URL-safe slug using a custom separator.
pub fn slugify_with_sep(str :: String, sep :: String) -> String do
  ""
end

# Truncate a slug to at most max characters, cutting at the last separator
# boundary so the result never ends mid-word.
pub fn truncate(slug :: String, max :: Int) -> String do
  ""
end

# Return true if the string is already a valid slug (lowercase alphanumeric
# and hyphens only, no leading/trailing/consecutive hyphens).
pub fn is_valid(slug :: String) -> Bool do
  false
end
