# React-PDF Manual

## Styling Reference

### Supported Units
`pt` (default, 72 DPI), `in`, `mm`, `cm`, `%`, `vw`, `vh`

### Common Style Properties
```tsx
{
  flexDirection: "row", justifyContent: "space-between", alignItems: "center",
  margin: 10, padding: 20, width: "100%", height: 200,
  borderWidth: 1, borderColor: "#333", borderRadius: 5,
  backgroundColor: "#f0f0f0", color: "#000",
  fontSize: 12, fontWeight: "bold", fontFamily: "Helvetica",
  textAlign: "center", textDecoration: "underline",
  position: "absolute", top: 0, left: 0, zIndex: 10,
}
```

## Advanced Components

### SVG Graphics
```tsx
import { Svg, Circle, Rect, Path } from "@react-pdf/renderer";

<Svg width="200" height="200" viewBox="0 0 200 200">
  <Circle cx="100" cy="100" r="50" fill="red" />
  <Rect x="10" y="10" width="50" height="50" fill="blue" />
</Svg>
```

### Dynamic Content and Page Numbers
```tsx
<Text render={({ pageNumber, totalPages }) => `Page ${pageNumber} of ${totalPages}`} />
```

### Fixed Headers/Footers
```tsx
<Page size="A4">
  <View fixed style={{ position: "absolute", top: 20, left: 30, right: 30 }}>
    <Text>Header on every page</Text>
  </View>
  <View style={{ marginTop: 60 }}>
    <Text>Main content</Text>
  </View>
</Page>
```

## Custom Fonts & Emoji

### Registering Fonts
**CRITICAL: Use local file paths.**
```tsx
Font.register({
  family: "Roboto",
  fonts: [
    { src: "./fonts/Roboto-Regular.ttf", fontWeight: "normal" },
    { src: "./fonts/Roboto-Bold.ttf", fontWeight: "bold" },
  ],
});
```

### Emoji Support
```bash
npm install twemoji-emojis
```
```tsx
Font.registerEmojiSource({
  format: "png",
  url: "node_modules/twemoji-emojis/vendor/72x72/",
});
```

## Best Practices & Troubleshooting
- **Async IIFE**: Always wrap `renderToFile` in `(async () => { ... })()`.
- **Hyphenation**: Disable for custom fonts using `Font.registerHyphenationCallback((word) => [word])`.
- **Preview**: Use `pdftoppm` to convert PDF to images for visual inspection.
- **Images**: Use local files for reliability. Remote URLs may fail.
