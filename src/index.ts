if (!process.env.LOG_ENABLED && process.env.LOG_ENABLED !== "true") process.env["LOG_ENABLED"] = 'true';

import { PDS, envToCfg, envToSecrets, readEnv, httpLogger } from "@atproto/pds";
import { checkHandleRoute } from "./check_handle_route";
import pkg from "@atproto/pds/package.json";

async function main() {
  const env = getEnv();
  const cfg = envToCfg(env);
  const secrets = envToSecrets(env);
  const pds = await PDS.create(cfg, secrets);
  console.log('server:', pds.server);

  await pds.start();
  httpLogger.info("pds has started");
  // Graceful shutdown (see also https://aws.amazon.com/blogs/containers/graceful-shutdowns-with-ecs/)
  pds.app.get("/tls-check", (req, res) => {
    checkHandleRoute(pds, req, res);
  });
  process.on("SIGTERM", async () => {
    httpLogger.info("pds is stopping");
    await pds.destroy();
    httpLogger.info("pds is stopped");
  });
}

const getEnv = () => {
  const env = readEnv();
  env.version ||= pkg.version;
  env.port ||= 3000;
  return env;
};

main();
