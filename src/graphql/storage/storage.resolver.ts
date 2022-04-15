import {
  Args,
  Int,
  Mutation,
  Parent,
  Query,
  ResolveField,
  Resolver,
} from '@nestjs/graphql';
import {
  AccessToken,
  Prisma,
  PrismaClient,
  Storage as StorageInterface,
} from '@prisma/client';
import { nanoid } from 'nanoid';
import QueryString = require('qs');
import { Auth } from 'src/shared/auth';
import { ResolveURLOnStorageBaseMetadataArgs } from './args/resolve_url_on_storage';
import { Storage } from './entities/storage';
import { UploadStorageMetadata } from './entities/upload_storage_metadata';
import {
  findSupportedStorageMetadata,
  SupportedStorageMetadata,
} from './supported_storage_metadatas';
import { TencentCloudObjectStorageClient } from './tencent_cloud_object_storage_client';

@Resolver(() => Storage)
export class StorageResolver {
  constructor(
    private readonly cos: TencentCloudObjectStorageClient,
    private readonly prisma: PrismaClient,
  ) {}

  @Query(() => Storage)
  storage(
    @Args('id', { type: () => String }) id: string,
  ): Prisma.Prisma__StorageClient<StorageInterface> {
    return this.prisma.storage.findUnique({
      where: { id },
      rejectOnNotFound: () => Error(`Storage ${id} not found`),
    });
  }

  @Mutation(() => UploadStorageMetadata, { nullable: true })
  @Auth.must()
  async createUploadStorageMetadata(
    @Auth.accessToken() { userId }: AccessToken,
    @Args('md5', {
      type: () => String,
      description: 'File md5 hash hex (32 bytes)',
    })
    md5: string,
    @Args('size', { type: () => Int, description: 'File size in bytes' })
    size: number,
    @Args('mimeType', { type: () => String, description: 'File MIME type' })
    mimeType: string,
  ) {
    // Find supported storage metadata
    const supportedStorageMetadata: SupportedStorageMetadata =
      findSupportedStorageMetadata(mimeType);

    // 32 bytes md5 hex converted to 16 bytes binary, then base64 encoded
    const encodedMD5: string = Buffer.from(md5, 'hex').toString('base64');

    // Build headers
    const headers: Record<string, any> = {
      'Content-MD5': encodedMD5,
      'Content-Type': mimeType,
      'Content-Length': size,
    };

    // Object basename
    const basename: string = nanoid(64);

    // YYYY: Year, Full length
    // MM: Month, 2 digits
    // DD: Day, 2 digits
    const now: Date = new Date();
    const year: string = now.getFullYear().toString();
    const month: string = (now.getMonth() + 1).toString().padStart(2, '0');
    const day: string = now.getDate().toString().padStart(2, '0');
    const location: string = `${year}/${month}/${day}/${basename}.${supportedStorageMetadata.extension}`;

    // Get signed URL
    const url: string = await this.cos.createObjectURL(location, {
      headers,
      method: 'PUT',
      expiresIn: 60 * 60 * 6, // 6 hours
    });

    return this.prisma.storage
      .create({
        data: {
          id: nanoid(64),
          isUploaded: false,
          location,
          userId,
        },
      })
      .then<UploadStorageMetadata>(({ id }) => ({
        id,
        url,
        headers: QueryString.stringify(headers),
      }));
  }

  @ResolveField('url', () => String)
  resolveURL(
    @Parent() { location }: Storage,
    @Args({ type: () => ResolveURLOnStorageBaseMetadataArgs })
    args?: ResolveURLOnStorageBaseMetadataArgs,
  ) {
    return this.cos.createObjectURL(location, {
      method: 'GET',
      expiresIn: 60 * 60 * 12, // 12 hours
      headers: QueryString.parse(args?.query ?? ''),
      query: QueryString.parse(args?.query ?? ''),
    });
  }
}
