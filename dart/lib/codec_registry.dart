// Copyright (c) 2021, Odroe Inc. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:grpc/grpc.dart';

const List<Codec> _codecs = [
  IdentityCodec(),
  GzipCodec(),
];

CodecRegistry codecRegistry = CodecRegistry(codecs: _codecs);