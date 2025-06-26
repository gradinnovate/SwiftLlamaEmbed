module.exports = {
  content: ["./_site/**/*.html", "./_site/**/*.js", "./assets/js/**/*.js"],
  css: ["./_site/assets/css/**/*.css"],
  output: "./_site/assets/css/",
  extractors: [
    {
      extractor: (content) => {
        // Extract class names from content
        return content.match(/[A-Za-z0-9-_:/]+/g) || [];
      },
      extensions: ["html", "js"],
    },
  ],
  // Safelist important classes that should never be purged
  safelist: [
    // Keep all Jekyll and Liquid generated classes
    /^(nav|navbar|hero|about|project|features|contact|testimonials)/,
    // Keep theme-related classes
    /^(theme|color|dark|light)/,
    // Keep animation and utility classes
    /^(fade|slide|active|show|hide)/,
    // Keep Font Awesome classes
    /^(fa|fas|far|fal|fad|fab)/,
    // Keep any data attributes
    /^data-/,
    // Common utility classes
    "container",
    "btn",
    "card",
    "modal",
    "dropdown",
  ],
  // Don't remove unused font-face declarations
  fontFace: false,
  // Don't remove unused keyframes
  keyframes: false,
  // Don't remove unused variables
  variables: false,
};
