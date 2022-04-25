import { ERROR_CODE_STORAGE_UNSUPPORTED_MIME_TYPE } from 'src/errorcodes';
import { SupportedStorageMetadata } from './metadata';
import { supportedStorageMetadatas } from './supported';

export function finder(mimeType: string): SupportedStorageMetadata {
  const metadata: SupportedStorageMetadata | undefined =
    supportedStorageMetadatas.find(
      (supportedStorageMetadata) =>
        supportedStorageMetadata.mimeType.toLocaleLowerCase() ===
        mimeType.toLocaleLowerCase(),
    );

  if (!(metadata instanceof SupportedStorageMetadata)) {
    throw new Error(ERROR_CODE_STORAGE_UNSUPPORTED_MIME_TYPE);
  }

  return metadata;
}
