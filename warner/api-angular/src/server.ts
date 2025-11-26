import {
  AngularNodeAppEngine,
  isMainModule,
  writeResponseToNodeResponse,
} from '@angular/ssr/node';

import type { IncomingMessage, ServerResponse } from 'http';
import { createServer } from 'node:http';

/**
 * Minimal server handler for Angular SSR without Express.
 *
 * - Exports `reqHandler(req, res)` which can be used by serverless platforms
 *   or by a custom Node HTTP server.
 * - This file intentionally does not import or depend on Express.
 */

const angularApp = new AngularNodeAppEngine();

export async function reqHandler(req: IncomingMessage, res: ServerResponse) {
  try {
    const response = await angularApp.handle(req as any);
    if (response) {
      writeResponseToNodeResponse(response, res as any);
    } else {
      // Not handled by Angular app — return 404
      res.statusCode = 404;
      res.end('Not Found');
    }
  } catch (err: any) {
    console.error('SSR handler error', err);
    res.statusCode = 500;
    res.end(err?.message || 'Server Error');
  }
}

// If someone runs this file directly, start a simple HTTP server for local testing.
if (isMainModule(import.meta.url)) {
  const port = Number(process.env['PORT'] || 4000);
  const server = createServer((req, res) => void reqHandler(req as IncomingMessage, res as ServerResponse));
  server.listen(port, () => {
    // eslint-disable-next-line no-console
    console.log(`Minimal SSR server listening on http://localhost:${port}`);
  });
}
