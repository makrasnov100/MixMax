module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
    jest: true,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  parserOptions: {
    ecmaVersion: 2020,
  },
  rules: {
    "quotes": ["error", "double"],
    "max-len": ["error", {
      "code": 120,
      "ignoreTemplateLiterals": true,
      "ignoreStrings": true,
      "ignoreComments": true,
    }],
    "object-curly-spacing": ["error", "always"],
    "array-bracket-spacing": "off",
    "spaced-comment": "off",
    "indent": "off",
    "linebreak-style": 0,
    "no-prototype-builtins": "off",
    "guard-for-in": "off",
    "no-trailing-spaces": ["error", {
      "skipBlankLines": true,
      "ignoreComments": true,
    }],

  },
};
