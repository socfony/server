// Copyright (c) 2021, Odroe Inc. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import { Module } from '@nestjs/common';
import { AuthModule } from 'src/auth';
import { OneTimePasswordModule } from 'src/one-time-password';
import { PrismaModule } from 'src/prisma.module';
import { AccessTokenResolver } from './access-token.resolver';
import { AccessTokenService } from './access-token.service';

@Module({
  imports: [PrismaModule, AuthModule, OneTimePasswordModule],
  providers: [AccessTokenService, AccessTokenResolver],
})
export class AccessTokenModule {}
