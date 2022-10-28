module.exports = {
  mode: 'jit',
  purge: {
    // enabled: true,
    content: [
      // './src/**/*.html',
      // './src/**/*.js',
      './src/views/**/*.ecr',
      // 'src/views/**/*.ecr',
    ],
  },
  darkMode: false,
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
  corePlugins: {
    float: false,
  },
}
