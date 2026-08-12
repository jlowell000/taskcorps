# TypeScript/JavaScript library quick reference

Package: `@toon-format/toon`

## Encode
```ts
import { encode } from '@toon-format/toon'

const data = { users: [{ id: 1, name: 'Alice' }] }
const toon = encode(data)
```

## Decode (strict by default)
```ts
import { decode } from '@toon-format/toon'

const obj = decode(toon, { strict: true }) // strict true is the default
```

## Streaming large datasets
```ts
import { encodeLines, decodeFromLines } from '@toon-format/toon'

// encodeLines: iterable of lines for memory-efficient output
for (const line of encodeLines(largeData, { delimiter: '\t' })) {
  process.stdout.write(line + '\n')
}

// decodeFromLines: decode buffered lines from streaming output
const obj = decodeFromLines(lines)
```

## Replacer (privacy & transformation)
Use a replacer to drop sensitive fields or transform values before encoding.
