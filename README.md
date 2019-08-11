# Notemarks

A markdown based note taking app.

Same motivation as [Notable](https://github.com/notable/notable), different appraoch.

## Installation

For now it is easiest to clone this repo and run

```sh
npm install
npm run build-all
npm start
```

## Notes storage directory

Currently, the app uses the folder `data` in the app directory store its markdown notes.
If you want to store your markdown notes in an independent git repository, it makes sense
to create a symlink of the `data` directory to wherever you want to store your notes.
