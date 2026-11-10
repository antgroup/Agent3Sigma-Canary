const adapter=require('../vendor/runtime-adapter-2'); if(typeof adapter.createSession!=='function') process.exit(1); console.log('client contract v2 compatible');
