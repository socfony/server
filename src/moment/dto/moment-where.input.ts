import { Field, InputType } from '@nestjs/graphql';
import { Prisma } from '@prisma/client';
import { DateTimeFilter, StringFilter } from 'src/graphql';

@InputType()
export class MomentWhereInput
  implements Omit<Prisma.MomentWhereInput, 'content' | 'media'>
{
  @Field(() => [MomentWhereInput], { nullable: true })
  AND?: Prisma.MomentWhereInput[];

  @Field(() => [MomentWhereInput], { nullable: true })
  OR?: Prisma.MomentWhereInput[];

  @Field(() => [MomentWhereInput], { nullable: true })
  NOT?: Prisma.MomentWhereInput[];

  @Field(() => StringFilter, { nullable: true })
  id?: StringFilter;

  @Field(() => StringFilter, { nullable: true })
  title?: StringFilter;

  @Field(() => DateTimeFilter, { nullable: true })
  createdAt?: DateTimeFilter;
}
