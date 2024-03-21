// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import fs from 'fs'
import yargs from 'yargs'
import { CSDL } from './definitions/RawTypes'
import { parseXML } from './parser'
import { constructDataStructure } from './deserializer'
import { Config } from './config'
import { Swagger } from './definitions/Swagger'
import { writeSwagger } from './swaggerWriter'
import { writeMetadata } from './metadataWriter'
import { validateReferences } from './validator'
import { DefinitionMap } from './definitions/DefinitionMap'
import { Metadata } from './definitions/Metadata'

const argv = yargs
  .option('output', {
    alias: 'o',
    description: 'The output file path',
    type: 'string',
    default: 'output',
    demandOption: true
  })
  .help()
  .parseSync();

const outputPath = argv.output;

async function parse(config: Config): Promise<[Metadata, Swagger]> {
  console.log(`Fetching MSGraph metadata CSDL for ${config.APIVersion}`);

  const csdl: CSDL = await parseXML(config.MetadataFilePath)

  let definitionMap: DefinitionMap = new DefinitionMap();
  definitionMap = constructDataStructure(csdl, definitionMap, config);
  definitionMap = validateReferences(definitionMap, config);

  const swagger: Swagger = writeSwagger(definitionMap, config);
  const metadata: Metadata = writeMetadata(definitionMap, config);

  return [metadata, swagger];
}

function writeSwaggerFile(swagger: Swagger, apiVersion: string) {
  const swaggerJson: string = JSON.stringify(swagger, null, 2);
  const fullOutputPath = `${outputPath}/${apiVersion}`;

  if (outputPath !== 'output') {
    if (!fs.existsSync(fullOutputPath)) {
      fs.mkdirSync(fullOutputPath, { recursive: true });
    }

    fs.writeFile(`${fullOutputPath}/microsoftgraph-${apiVersion}.json`, swaggerJson, (err) => {
      if (err) throw err;
      console.log(`The swagger file spec for ${apiVersion} has been saved!`);
    });
  }

  fs.writeFile(`output/microsoftgraph-${apiVersion}.json`, swaggerJson, (err) => {
    if (err) throw err;
    console.log(`The output for ${apiVersion} has been saved.`);
  });
}

function writeMetadataFile(metadata: Metadata) {
  const metadataJson: string = JSON.stringify(metadata, null, 2);

  fs.writeFile(`output/metadata.json`, metadataJson, (err) => {
    if (err) throw err;
    console.log(`The metadata file has been saved!`);
  });
}

async function main() {
  const apiVersions = ["beta", "v1.0"]
  let metadata: Metadata = {};

  for (const apiVersion of apiVersions) {
    const config = new Config(apiVersion);
    const [curMetadata, curSwagger] = await parse(config);

    // Merge the metadata for current api version with the existing metadata
    for (const entityName in curMetadata) {
      metadata[entityName] ??= {};
      metadata[entityName][apiVersion] = curMetadata[entityName][apiVersion];
    }

    writeSwaggerFile(curSwagger, apiVersion);
  }

  writeMetadataFile(metadata);
}

main();
