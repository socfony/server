// Copyright (c) 2021, Odroe Inc. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import { InputType, PartialType, PickType } from '@nestjs/graphql';
import { Prisma } from '@prisma/client';
import { User } from '../entities/user.entity';

@InputType({ description: 'User unique where input' })
export class UserWhereUniqueInput
  extends PartialType(
    PickType(User, ['id', 'email', 'phone', 'username'] as const),
    InputType,
  )
  implements Prisma.UserWhereUniqueInput {}