# Shopify product importer

- create stream of product nodes
- write each product to disk
  - transform nodes to domain
  - serialize domain products (for hugo)
  - write products (to disk)
- download each image
  - check which images need downloading
  - download images

## Needed structure for frontend

- identification
  - handle
  - legacy id
- basic product specifics
  - title
  - price
  - available (for indicating sold out products)
- calculated product specifics
  - has price range (for "from...")
  - compare at price (for "discount" thingy)
- shopify pim workaround
  - description (html)
  - features text (not implemented currently)
  - features tags (not implemented currently)
  - materials text (not implemented currently)
  - care text (not implemented currently)
- resources
  - name (for sorting)
  - src
- options array
  - name
  - first available value?
  - values array
    - name
    - checked initially?
    - available initially
- variants
  - id (for add to cart)
  - available
  - price
  - compare at price
  - image name (for scrolling on color change)
  - options (for getting the variant)
    - name: value