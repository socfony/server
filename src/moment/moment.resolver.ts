import {
  Args,
  ID,
  Int,
  Mutation,
  Parent,
  Query,
  ResolveField,
  Resolver,
} from '@nestjs/graphql';
import {
  Prisma,
  PrismaClient,
  Moment as _Moment,
  User as _User,
  Comment as _Comment,
  PrismaPromise,
  AccessToken,
} from '@prisma/client';
import { nanoid } from 'nanoid';
import { Auth } from 'src/auth';
import { Comment } from 'src/comment/entities/comment.entity';
import { User } from 'src/user/entities/user.entity';
import { MomentCreateInput } from './dto/moment-create.input';
import { MomentFindManyArgs } from './dto/moment-find-many.args';
import { Moment } from './entities/moment.entity';

@Resolver(() => Moment)
export class MomentResolver {
  constructor(private readonly prisma: PrismaClient) {}

  @Query(() => Moment, { nullable: true, description: 'Find a moment.' })
  moment(
    @Args({ name: 'id', type: () => ID, description: 'Moment ID.' }) id: string,
  ): Prisma.Prisma__MomentClient<_Moment | null> {
    return this.prisma.moment.findUnique({
      where: { id },
      rejectOnNotFound: false,
    });
  }

  @Query(() => [Moment], { description: 'Find moments.', nullable: 'items' })
  moments(
    @Args({ type: () => MomentFindManyArgs }) args: MomentFindManyArgs,
  ): PrismaPromise<_Moment[]> {
    return this.prisma.moment.findMany(args);
  }

  @Mutation(() => Moment, { description: 'Create a moment.' })
  @Auth.must()
  createMoment(
    @Args({ name: 'data', type: () => MomentCreateInput })
    { media, title, content }: MomentCreateInput,
    @Auth.accessToken() { userId }: AccessToken,
  ): Prisma.Prisma__MomentClient<_Moment> {
    return this.prisma.moment.create({
      data: {
        id: nanoid(64),
        userId,
        title: title && title.trim().length > 0 ? title.trim() : undefined,
        content:
          content && content.trim().length > 0 ? content.trim() : undefined,
        media,
      },
    });
  }

  @Mutation(() => Moment, { description: 'Like a moment.' })
  @Auth.must()
  async likeMoment(
    @Args({ name: 'momentId', type: () => ID }) id: string,
    @Auth.accessToken() { userId }: AccessToken,
  ): Promise<_Moment> {
    const { id: momentId } = await this.prisma.moment.findUnique({
      where: { id },
      select: { id: true },
      rejectOnNotFound: true,
    });

    const result = await this.prisma.userLikeOnMoment.upsert({
      where: {
        userId_momentId: { userId, momentId },
      },
      update: {},
      create: { userId, momentId },
      select: { moment: true },
    });

    return result.moment;
  }

  @Mutation(() => Boolean, { description: 'Unlike a moment.' })
  @Auth.must()
  async unlikeMoment(
    @Args({ name: 'momentId', type: () => ID }) momentId: string,
    @Auth.accessToken() { userId }: AccessToken,
  ): Promise<boolean> {
    await this.prisma.userLikeOnMoment.delete({
      where: {
        userId_momentId: { userId, momentId },
      },
    });

    return true;
  }

  @Mutation(() => Comment, { description: 'Create a moment comment.' })
  @Auth.must()
  async createMomentComment(
    @Args({ name: 'id', type: () => ID, description: 'Moment ID.' }) id: string,
    @Args({
      name: 'content',
      type: () => String,
      description: 'Comment content.',
    })
    content: string,
    @Auth.accessToken() { userId }: AccessToken,
  ) {
    const moment = await this.prisma.moment.findUnique({
      where: { id },
      rejectOnNotFound: true,
    });

    return this.prisma.comment.create({
      data: {
        id: nanoid(64),
        content,
        userId,
        momentId: moment.id,
      },
    });
  }

  @ResolveField(() => User)
  user(
    @Parent()
    { userId, user }: Prisma.MomentGetPayload<{ include: { user: true } }>,
  ): Prisma.Prisma__UserClient<_User> | Promise<_User> {
    if (user) return Promise.resolve<_User>(user);

    return this.prisma.user.findUnique({
      where: { id: userId },
      rejectOnNotFound: true,
    });
  }

  @ResolveField(() => [User])
  async likedUsers(
    @Parent() { id }: _Moment,
    @Args({ name: 'take', type: () => Int, nullable: true, defaultValue: 15 })
    take: number = 15,
    @Args({ name: 'skip', type: () => Int, nullable: true }) skip?: number,
  ): Promise<_User[]> {
    const results = await this.prisma.userLikeOnMoment.findMany({
      where: { momentId: id },
      orderBy: { createdAt: 'desc' },
      select: { user: true },
      take,
      skip,
    });

    return results.map(({ user }) => user);
  }

  @ResolveField(() => [Comment])
  comments(
    @Parent() { id }: _Moment,
    @Args({ name: 'take', type: () => Int, nullable: true, defaultValue: 15 })
    take: number = 15,
    @Args({ name: 'skip', type: () => Int, nullable: true }) skip?: number,
  ): PrismaPromise<_Comment[]> {
    return this.prisma.comment.findMany({
      where: { momentId: id },
      orderBy: { createdAt: 'desc' },
      take,
      skip,
    });
  }
}
