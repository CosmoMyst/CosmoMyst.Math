module cosmomyst.math.vector;

alias vec2 = vec!2;
alias vec3 = vec!3;
alias vec4 = vec!4;

/++
 + vec struct with optional amount of components.
 +/
struct vec(ulong n) if (n >= 2) {
    union {
        /++
         + internal data
         +/
        float[n] v;

        struct {
            static if (n >= 1) {
                float x;
            }

            static if (n >= 2) {
                float y;
            }

            static if (n >= 3) {
                float z;
            }

            static if (n >= 4) {
                float w;
            }
        }
    }

    @nogc this(T...)(T args) pure nothrow {
        static foreach (arg; args) {
            static assert(is(typeof(arg) == float) || is(typeof(arg) == const(float)), "all values must be of type float");
        }

        static assert(args.length > 0, "no args provided");

        static assert(args.length == 1 || args.length == n, "number of args must be either 1 or number of components");

        static if (args.length == 1) {
            static foreach (i; 0..n) {
                v[i] = args[0];
            }
        } else {
            static foreach (i, arg; args) {
                v[i] = arg;
            }
        }
    }

    /++
     + internal data as a pointer, use for sending data to shaders.
     +/
    @nogc auto ptr() pure nothrow const {
        return v.ptr;
    }

    @nogc float length() pure nothrow const {
        import std.math : sqrt;

        float sum = 0;
        for (int i = 0; i < n; i++) {
            sum += v[i] * v[i];
        }

        return sqrt(sum);
    }

    /++
     + normalizes the vectors. changes the current struct!
     +/
    @nogc void normalize() pure nothrow {
        this = this / length();
    }

    /++
     + returns the normalized vector. doesn't change the current struct!
     +/
    @nogc vec!n normalized() pure nothrow const {
        auto res = this / length();
        return res;
    }

    string toString() const {
        import std.string : format;
        return format("%s", v);
    }

    /++
     + returns the negated vector.
     +/
    @nogc vec!n opUnary(string s)() const if (s == "-") {
        vec!n res;
        for (int i = 0; i < n; i++) {
            res.v[i] = -v[i];
        }
        return res;
    }

    /++
     + returns the sub of 2 vectors.
     +/
    @nogc vec!n opBinary(string s) (const vec!n other) const if (s == "-") {
        vec!n res;
        for (int i = 0; i < n; i++) {
            res.v[i] = v[i] - other.v[i];
        }
        return res;
    }

    /++
     + returns the div of 2 vectors.
     +/
    @nogc vec!n opBinary(string s) (in float scalar) const if (s == "/") {
        vec!n res;
        for (int i = 0; i < n; i++) {
            res.v[i] = v[i] / scalar;
        }
        return res;
    }

    /++
     + returns the dot product of 2 vectors.
     +/
    @nogc static float dot(vec!n a, vec!n b) pure nothrow {
        import std.format : format;
        float res = 0f;
        static foreach (i; 0..n) {
            mixin(format!("res += a.v[%s] * b.v[%s];")(i, i));
        }
        return res;
    }

    /++
     + returns the cross product of 2 vectors.
     +/
    @nogc static vec!3 cross(vec!3 a, vec!3 b) pure nothrow {
        return vec!3(a.y * b.z - a.z * b.y,
                     a.z * b.x - a.x * b.z,
                     a.x * b.y - a.y * b.x);
    }
}

unittest {
    auto t1 = vec2(2f, 3f);

    assert(t1.x == 2f);
    assert(t1.y == 3f);

    auto t2 = vec2(2f);
    assert(t2.x == 2f);
    assert(t2.y == 2f);

    assert(t1.toString() == "[2, 3]");
}

unittest {
    auto t1 = vec3(5f, 2f, 6f);
    assert(t1.length() == 8.06225774829855f);
}

unittest {
    auto t1 = vec3(2f, 5f, 3f);
    auto t2 = vec3(7f, 4f, 9f);
    assert(vec3.dot(t1, t2) == 61);
}

unittest {
    auto t1 = vec3(2f, 3f, 4f);
    auto t2 = vec3(5f, 6f, 7f);
    assert(vec3.cross(t1, t2) == vec3(-3f, 6f, -3f));
}

unittest {
    auto t1 = vec3(5f, 2f, 7f);
    assert(-t1 == vec3(-5f, -2f, -7f));
}

unittest {
    auto t1 = vec3(5f, 2f, 7f);
    auto t2 = vec3(3f, 7f, 2f);
    assert(t1 - t2 == vec3(2f, -5f, 5f));
}
