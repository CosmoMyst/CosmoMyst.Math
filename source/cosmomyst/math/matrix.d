module cosmomyst.math.matrix;

import cosmomyst.math.core;
import cosmomyst.math.vector;

alias mat2 = mat!2;
alias mat3 = mat!3;
alias mat4 = mat!4;

/++
 + a square NxN matrix
 +/
struct mat(ulong n) if (n >= 2) {
    union {
        float[n*n] v; // all values
        float[n][n] c; // all components
    }

    @nogc this(T...)(T args) pure nothrow {
        static foreach (arg; args) {
            static assert(is(typeof(arg) == float) || is(typeof(arg) == const(float)), "all values must be of type float");
        }

        static assert(args.length > 0, "no args provided");

        static assert(args.length == 1 || args.length == n*n, "number of args must be ither 1 or N*N");

        static if (args.length == 1) {
            static foreach (i; 0..n*n) {
                v[i] = args[0];
            }
        } else {
            static foreach (i, arg; args) {
                v[i] = arg;
            }
        }
    }

    /++
     + get the value at [i, j]
     +/
    @nogc float opIndex(int i, int j) pure const nothrow {
        return c[i][j];
    }

    /++
     + set the value at [i, j]
     +/
    @nogc float opIndexAssign(float value, int i, int j) pure nothrow {
        return c[i][j] = value;
    }

    /++
     + returns this matrix * scalar
     +/
    @nogc auto opBinary(string s) (const float scalar) pure const nothrow if (s == "*") {
        mat res;

        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                res[i, j] = this[i, j] * scalar;
            }
        }

        return res;
    }

    /++
     + returns this matrix * scalar
     +/
    @nogc void opOpAssign(string s) (const float scalar) pure nothrow if (s == "*") {
        auto res = this * scalar;
        this.v = res.v;
    }

    /++
     + returns this matrix * vector
     +/
    @nogc auto opBinary(string s) (const vec!n vector) pure const nothrow if (s == "*") {
         vec!n res;

         for (int i = 0; i < n; i++) {
             float sum = 0f;
             for (int j = 0; j < n; j++) {
                 sum += this[i, j] * vector[j];
             }
             res[i] = sum;
         }

         return res;
    }

    /++
     + returns this matrix * matrix
     +/
    @nogc auto opBinary(string s) (const mat!n other) pure const nothrow if (s == "*") {
        mat!n res;

        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                float sum = 0f;
                for (int k = 0; k < n; k++) {
                    sum += this[i, k] * other[k, j];
                }
                res[i, j] = sum;
            }
        }

        return res;
    }

    /++
     + returns this matrix * matrix
     +/
    @nogc void opOpAssign (string s) (const mat!n other) pure nothrow if (s == "*") {
        auto res = this * other;
        this.v = res.v;
    }

    /++
     + returns sum or sub of two matrices
     +/
     @nogc auto opBinary(string s) (const mat!n other) pure const nothrow if (s == "+" || s == "-") {
        mat!n res;

        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                mixin("res[i, j] = this[i, j] " ~ s ~ " other[i, j];");
            }
        }

        return res;
     }

    string toString() {
        import std.format : format;
        return format!("%s")(c);
    }

    /++
     + internal data as a pointer, use for sending data to shaders.
     +/
    @nogc auto ptr() pure nothrow const {
        return v.ptr;
    }
}

/++
 + creates an identity matrix
 +/
@nogc mat!n mat_ident(ulong n)() pure nothrow {
    mat!n res;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            res[i, j] = i == j ? 1f : 0f;
        }
    }
    return res;
}

/++
 + creates a scaling matrix
 +/
@nogc mat!n mat_scaling(ulong n)(vec!(n-1) v) pure nothrow {
    auto res = mat_ident!n();
    for (int i = 0; i + 1 < n; i++) {
        res[i, i] = v[i];
    }
    return res;
}

/++
 + creates a rotation matrix, angle must be in radians
 +/
@nogc mat4 mat_rotation(float angle, vec3 axis) pure nothrow {
    import std.math : sin, cos;

    auto res = mat_ident!4();
    float c = cos(angle);
    float c1 = 1 - c;
    float s = sin(angle);

    auto a = axis.normalized();

    res[0, 0] = a.x * a.x * c1 + c;
    res[0, 1] = a.x * a.y * c1 - a.z * s;
    res[0, 2] = a.x * a.z * c1 + a.y * s;
    res[1, 0] = a.y * a.x * c1 + a.z * s;
    res[1, 1] = a.y * a.y * c1 + c;
    res[1, 2] = a.y * a.z * c1 - a.x * s;
    res[2, 0] = a.z * a.x * c1 - a.y * s;
    res[2, 1] = a.z * a.y * c1 + a.x * s;
    res[2, 2] = a.z * a.z * c1 + c;

    return res;
}

/++
 + creates a translation matrix
 +/
@nogc auto mat_translation(ulong n)(vec!(n-1) v) pure nothrow {
    auto res = mat_ident!n();
    for (int i = 0; i + 1 < n; i++) {
        res[i, n-1] = res[i, n-1] + v[i];
    }
    return res;
}

/++
 + creates a look_at matrix
 +/
@nogc mat4 mat_look_at(vec3 eye, vec3 target, vec3 up) pure nothrow {
    vec3 z = (eye - target).normalized();
    vec3 x = vec_cross(-up, z).normalized();
    vec3 y = vec_cross(z, -x);

    return mat4(-x.x, -x.y, -x.z,  vec_dot!3(x, eye),
                 y.x,  y.y,  y.z, -vec_dot!3(y, eye),
                 z.x,  z.y,  z.z, -vec_dot!3(z, eye),
                 0f,   0f,   0f,   1f);
}

/++
 + creates an orthographic projection matrix
 +/
@nogc mat4 mat_orthographic(float left, float right, float bottom, float top, float near, float far) pure nothrow {
    float dx = right - left;
    float dy = top - bottom;
    float dz = far - near;

    float tx = -(right + left) / dx;
    float ty = -(top + bottom) / dy;
    float tz = -(far + near) / dz;

    return mat4(2/dx, 0f,    0f,   tx,
                0f,   2/dy,  0f,   ty,
                0f,   0f,   -2/dz, tz,
                0f,   0f,    0f,   1f);
}

/++
 + creates a perspective projection matrix
 +/
@nogc mat4 mat_perspective(float fov_in_radians, float aspect, float near, float far) pure nothrow {
    import std.math : tan;

    float f = 1 / tan(fov_in_radians / 2);
    float d = 1 / (near - far);

    return mat4(f / aspect, 0f, 0f,               0f,
                0f,         f,  0f,               0f,
                0f,         0f, (far + near) * d, 2 * d * far * near,
                0f,         0f, -1f,              0f);
}

unittest {
    auto t1 = mat2(2f);
    auto t2 = mat2(1f, 2f, 3f, 4f);

    assert(t1[0, 0] == 2f);
    assert(t1[0, 1] == 2f);
    assert(t1[1, 0] == 2f);
    assert(t1[1, 1] == 2f);

    assert(t2[0, 0] == 1f);
    assert(t2[0, 1] == 2f);
    assert(t2[1, 0] == 3f);
    assert(t2[1, 1] == 4f);

    t1[0, 0] = 5f;
    assert(t1[0, 0] == 5f);

    assert(t1.toString() == "[[5, 2], [2, 2]]");
}

unittest {
    auto t1 = mat2(1f, 2f, 3f, 4f);
    assert(t1 * 2f == mat2(2f, 4f, 6f, 8f));
}

unittest {
    auto m1 = mat2(1f, 2f, 3f, 4f);
    auto v1 = vec2(4f, 6f);
    assert(m1 * v1 == vec2(16f, 36f));
}

unittest {
    auto m1 = mat2(1f, 2f, 3f, 4f);
    auto m2 = mat2(5f, 6f, 7f, 8f);
    assert(m1 * m2 == mat2(19f, 22f, 43f, 50f));
    m1 *= m2;
    assert(m1 == mat2(19f, 22f, 43f, 50f));
}

unittest {
    auto m1 = mat2(1f, 2f, 3f, 4f);
    auto m2 = mat2(5f, 6f, 7f, 8f);
    assert(m1 + m2 == mat2(6f, 8f, 10f, 12f));
}

unittest {
    auto m1 = mat2(5f, 6f, 7f, 8f);
    auto m2 = mat2(1f, 2f, 3f, 4f);
    assert(m1 - m2 == mat2(4f));
}

unittest {
    auto m1 = mat_ident!2();
    assert(m1 == mat2(1f, 0f, 0f, 1f));
}

unittest {
    auto scaling = mat_scaling!2(vec!1(3f));
    assert(scaling == mat2(3f, 0f, 0f, 1f));

    auto m1 = mat2(1f, 2f, 3f, 4f);
    assert(m1 * scaling == mat2(3f, 2f, 9f, 4f));
}

unittest {
    auto trans = mat_translation!3(vec2(4f));
    assert(trans == mat3(1f, 0f, 4f, 0f, 1f, 4f, 0f, 0f, 1f));

    auto m1 = mat3(3f);
    assert(m1 * trans == mat3(3f, 3f, 27f, 3f, 3f, 27f, 3f, 3f, 27f));
}
