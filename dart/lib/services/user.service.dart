// Copyright (c) 2021, Odroe Inc. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:grpc/grpc.dart';
import 'package:server/database/connection_pool.dart';
import 'package:single/single.dart';
import 'package:socfonyapis/socfonyapis.dart';

import '../auth.dart';

class UserService extends UserServiceBase {
  @override
  Future<User> findUnique(
      ServiceCall call, FindUniqueUserRequest request) async {
    final FindUniqueUserRequest_Unique kind = request.whichUnique();
    if (kind == FindUniqueUserRequest_Unique.notSet) {
      throw GrpcError.invalidArgument('Request must set one of the fields');
    }

    final String field = kind.name;
    final String value = request.getField(request.getTagNumber(field)!);
    final database = await single<DatabaseConnectionPool>().getConnection();

    final results = await database.mappedResultsQuery(
      'SELECT * FROM users WHERE $field = @value',
      substitutionValues: {'value': value},
    );

    if (results.isEmpty) {
      throw GrpcError.notFound('User not found');
    }

    final result = results.single['users']!;

    return User()
      ..id = result['id']
      ..name = result['name']
      ..phone = _desensitization(result['phone'])
      ..createdAt = Timestamp.fromDateTime(result['created_at']);
  }

  String _desensitization(String value) {
    final length = value.length;
    final half = length ~/ 2;
    return '${value.substring(0, half)}${'*' * (length - half)}';
  }

  @override
  Future<UserList> findMany(
      ServiceCall call, FindManyUserRequest request) async {
    if (request.where.isEmpty) {
      throw GrpcError.invalidArgument('Request must set where');
    }

    final List<String> ids = request.where
        .where((element) =>
            element.whichUnique() == FindUniqueUserRequest_Unique.id)
        .map((element) => element.id)
        .toSet()
        .toList();
    final List<String> names = request.where
        .where((element) =>
            element.whichUnique() == FindUniqueUserRequest_Unique.name)
        .map((element) => element.name)
        .toSet()
        .toList();
    final List<String> phones = request.where
        .where((element) =>
            element.whichUnique() == FindUniqueUserRequest_Unique.phone)
        .map((element) => element.phone)
        .toSet()
        .toList();

    if ((ids.length + names.length + phones.length) > 100) {
      throw GrpcError.invalidArgument('Too many conditions, max 100');
    }

    final Map<String, String> substitutionValues = {};
    final wheres = <String>[];
    if (ids.isNotEmpty) {
      final keys = <String>[];
      for (int i = 0; i < ids.length; i++) {
        keys.add('@id$i');
        substitutionValues['id$i'] = ids[i];
      }
      wheres.add('id IN (${keys.join(', ')})');
    }
    if (names.isNotEmpty) {
      final keys = <String>[];
      for (int i = 0; i < names.length; i++) {
        keys.add('@name$i');
        substitutionValues['name$i'] = names[i];
      }
      wheres.add('name IN (${keys.join(', ')})');
    }
    if (phones.isNotEmpty) {
      final keys = <String>[];
      for (int i = 0; i < phones.length; i++) {
        keys.add('@phone$i');
        substitutionValues['phone$i'] = phones[i];
      }
      wheres.add('phone IN (${keys.join(', ')})');
    }

    final database = await single<DatabaseConnectionPool>().getConnection();
    final results = await database.mappedResultsQuery(
      'SELECT * FROM users WHERE ${wheres.join(' OR ')} LIMIT 100',
      substitutionValues: substitutionValues,
    );

    final users = results.map((element) {
      final user = element['users']!;
      final result = User();
      result.id = user['id'];
      result.name = user['name'];
      result.phone = _desensitization(user['phone']);
      result.createdAt = Timestamp.fromDateTime(user['created_at']);
      return result;
    });
    final response = UserList(user: users);

    return response;
  }

  @override
  Future<UserList> search(ServiceCall call, SearchUserRequest request) async {
    final String keyword = request.keyword;
    final int limit = request.hasLimit() ? request.limit : 15;
    final int offset = request.hasOffset() ? request.offset : 0;
    final database = await single<DatabaseConnectionPool>().getConnection();

    // Search `name` field in users/user_profiles table.
    final results = await database.mappedResultsQuery(
      r'SELECT users.* FROM users LEFT JOIN user_profiles ON users.id = user_profiles.user_id WHERE users.name ILIKE @keyword OR user_profiles.name ILIKE @keyword LIMIT @limit OFFSET @offset',
      substitutionValues: {
        'keyword': keyword,
        'limit': limit,
        'offset': offset,
      },
    );

    return UserList(
      user: results.map((element) {
        final user = element['users']!;
        final result = User();
        result.id = user['id'];
        result.name = user['name'];
        result.phone = _desensitization(user['phone']);
        result.createdAt = Timestamp.fromDateTime(user['created_at']);
        return result;
      }),
    );
  }

  @override
  Future<Empty> updateAccountName(ServiceCall call, StringValue request) async {
    final accessToken =
        await single<Auth>().getAccessToken(call.clientMetadata);
    single<Auth>().validate(accessToken: accessToken);

    // Find user by name.
    final database = await single<DatabaseConnectionPool>().getConnection();
    final results = await database.mappedResultsQuery(
      'SELECT * FROM users WHERE name = @name AND id != @id',
      substitutionValues: {
        'name': request.value,
        'id': accessToken!.userId,
      },
    );

    // If results not empty, name is already used.
    if (results.isNotEmpty) {
      throw GrpcError.invalidArgument(
          'Account name ${request.value} is already used');
    }

    // Update current user name.
    await database.execute(
      'UPDATE users SET name = @name WHERE id = @id',
      substitutionValues: {
        'name': request.value,
        'id': accessToken.userId,
      },
    );

    return Empty();
  }

  @override
  Future<Empty> updatePhone(
      ServiceCall call, UpdateUserPhoneRequest request) async {
    final Auth auth = single<Auth>();
    final accessToken = await auth.getAccessToken(call.clientMetadata);

    // Validate access token.
    auth.validate(accessToken: accessToken);

    // Find request phone user.
    final database = await single<DatabaseConnectionPool>().getConnection();
    final results = await database.mappedResultsQuery(
      'SELECT * FROM users WHERE phone = @phone',
      substitutionValues: {
        'phone': request.phone,
      },
    );

    // If results not empty, and id not same current user id, phone is already used.
    if (results.isNotEmpty &&
        results.first['users']!['id'] != accessToken!.userId) {
      throw GrpcError.invalidArgument('Phone ${request.phone} is already used');
    }

    // Get current user.
    final user = await auth.getUser(call.clientMetadata);

    // If current user phone is request phone, return.
    if (user!['phone'] == request.phone) {
      return Empty();
    }

    void Function()? done1;
    // If current user phone is not empty, Check request pre_phone_otp.
    if (user['phone'] != null || (user['phone'] as String).isNotEmpty) {
      done1 = await _validateOtp(user['phone'], request.prePhoneOtp);
    }

    // Check request phone and otp
    final done2 = await _validateOtp(request.phone, request.otp);

    // Update current user phone.
    await database.execute(
      'UPDATE users SET phone = @phone WHERE id = @id',
      substitutionValues: {
        'phone': request.phone,
        'id': accessToken!.userId,
      },
    );

    // Done all.
    done1?.call();
    done2();

    return Empty();
  }

  Future<void Function()> _validateOtp(String phone, String otp) async {
    final database = await single<DatabaseConnectionPool>().getConnection();
    final results = await database.mappedResultsQuery(
      r'SELECT * FROM verification_codes WHERE phone = @phone AND otp = @otp',
      substitutionValues: {
        'phone': phone,
        'otp': otp,
      },
    );

    // If results is empty, otp is invalid.
    if (results.isEmpty) {
      throw GrpcError.invalidArgument('Invalid otp');
    }

    return () async {
      // Delete verification code.
      await database.execute(
        r'DELETE FROM verification_codes WHERE phone = @phone AND otp = @otp',
        substitutionValues: {
          'phone': phone,
          'otp': otp,
        },
      );
      // Delete all expired verification code.
      await database.execute(
        r'DELETE FROM verification_codes WHERE created_at < NOW()',
      );
    };
  }
}