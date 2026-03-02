# mesh-slug — URL-safe slug generation for Mesh.
# This is the package entry point. Consumers import via:
#   from Slug import slugify, slugify_with_sep, truncate, is_valid

from Slug import slugify, slugify_with_sep, truncate, is_valid

fn main() do
  let example = slugify("Hello World!")
  println(example)
end
