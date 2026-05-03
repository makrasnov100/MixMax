## Useful commands

### Set env variables (from package.json of functions folder)

dev env: `npm run config:set:dev`
prod env: `npm run config:set:prod`

### Deploy functions (from root)

use project - `firebase use dev` or `firebase use prod`

then

dev: `firebase deploy --only functions --project dev`
prod: `firebase deploy --only functions`
