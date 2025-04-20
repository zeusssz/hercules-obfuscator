function GetOpcodeCode(S)
	if (S == 0) then
		return [=[X[Inst.A] = X[Inst.B];]=]
	elseif (S == 1) then
		return [=[X[Inst.A] = (type(Inst.D) == "number" and Inst.D % 1 == 0) and math.floor(Inst.D) or Inst.D]=]
	elseif (S == 2) then
		return [=[
        X[Inst.A] = Inst.B ~= 0
        if Inst.C ~= 0 then z = z + 1 end;
        ]=]
	elseif (S == 3) then
		return [=[
        for i = Inst.A, Inst.B do X[i] = nil end;
        ]=]
	elseif (S == 4) then
		return [=[
        local Uv = n[Inst.B]
        X[Inst.A] = Uv.M[Uv.N]
        ]=]
	elseif (S == 5) then
		return [=[
        X[Inst.A] = Env[Inst.D]
        ]=]
	elseif (S == 6) then
		return [=[
        local N
        if Inst.a then
            N = Inst.C;
        else
            N = X[Inst.C]
        end
        X[Inst.A] = X[Inst.B][N]
        ]=]
	elseif (S == 7) then
		return [=[
        Env[Inst.D] = X[Inst.A]
        ]=]
	elseif (S == 8) then
		return [=[
        local Uv = n[Inst.B]
        Uv.M[Uv.N] = X[Inst.A]
        ]=]
	elseif (S == 9) then
		return [=[
        local N, m
        if Inst.s then
            N = Inst.A
        else
            N = X[Inst.B]
        end
        if Inst.a then
            m = Inst.C
        else
            m = X[Inst.C]
        end
        X[Inst.A][N] = m
        ]=]
	elseif (S == 10) then
		return [=[
        X[Inst.A] = {}
        ]=]
	elseif (S == 11) then
		return [=[
        local A = Inst.A
        local B = Inst.B
        local N;
        if Inst.a then
            N = Inst.C
        else
            N = X[Inst.C]
        end
        X[A + 1] = X[B]
        X[A] = X[B][N]
        ]=]
	elseif (S == 12) then
		return [=[
        local Lhs, Rhs;
        if Inst.s then
            Lhs = Inst.A
        else
            Lhs = X[Inst.B]
        end
        if Inst.a then
            Rhs = Inst.C
        else
            Rhs = X[Inst.C]
        end
        X[Inst.A] = NormalizeNumber(Lhs + Rhs)
        ]=]
	elseif (S == 13) then
		return [=[
        local Lhs, Rhs;
        if Inst.s then
            Lhs = Inst.A
        else
            Lhs = X[Inst.B]
        end
        if Inst.a then
            Rhs = Inst.C
        else
            Rhs = X[Inst.C]
        end
        X[Inst.A] = NormalizeNumber(Lhs - Rhs)
        ]=]
	elseif (S == 14) then
		return [=[
        local Lhs, Rhs;
        if Inst.s then
            Lhs = Inst.A
        else
            Lhs = X[Inst.B]
        end
        if Inst.a then
            Rhs = Inst.C
        else
            Rhs = X[Inst.C]
        end
        X[Inst.A] = NormalizeNumber(Lhs * Rhs)
        ]=]
	elseif (S == 15) then
		return [=[
        local Lhs, Rhs;
        if Inst.s then
            Lhs = Inst.A
        else
            Lhs = X[Inst.B]
        end
        if Inst.a then
            Rhs = Inst.C
        else
            Rhs = X[Inst.C]
        end
        X[Inst.A] = NormalizeNumber(Lhs / Rhs)
        ]=]
	elseif (S == 16) then
		return [=[
        local Lhs, Rhs;
        if Inst.s then
            Lhs = Inst.A
        else
            Lhs = X[Inst.B]
        end
        if Inst.a then
            Rhs = Inst.C
        else
            Rhs = X[Inst.C]
        end
        X[Inst.A] = NormalizeNumber(Lhs % Rhs)
        ]=]
	elseif (S == 17) then
		return [=[
        local Lhs, Rhs;
        if Inst.s then
            Lhs = Inst.A
        else
            Lhs = X[Inst.B]
        end
        if Inst.a then
            Rhs = Inst.C
        else
            Rhs = X[Inst.C]
        end
        X[Inst.A] = NormalizeNumber(Lhs ^ Rhs)
        ]=]
	elseif (S == 18) then
		return [=[
        X[Inst.A] = NormalizeNumber(-X[Inst.B])
        ]=]
	elseif (S == 19) then
		return [=[
        X[Inst.A] = not X[Inst.B]
        ]=]
	elseif (S == 20) then
		return [=[X[Inst.A] = #X[Inst.B]]=]
	elseif (S == 21) then
		return [=[
        local B, C = Inst.B, Inst.C;
        local Str = "";
        for i = B, C do
            local v = X[i];
            if type(v) == "number" then
                if v % 1 == 0 then
                    Str = Str .. string.format("%d", v)
                else
                    Str = Str .. string.format("%g", v)
                end
            else
                Str = Str .. tostring(v)
            end
        end
        X[Inst.A] = Str;
    ]=]
	elseif (S == 22) then
		return [=[z = z + Inst.f]=]
	elseif (S == 23) then
		return [=[
        local Lhs, Rhs;
        if Inst.s then
            Lhs = Inst.A
        else
            Lhs = X[Inst.B]
        end
        if Inst.a then
            Rhs = Inst.C
        else
            Rhs = X[Inst.C]
        end
        if (Lhs == Rhs) == (Inst.A ~= 0) then z = z + x[z].f end;
        z = z + 1
        ]=]
	elseif (S == 24) then
		return [=[
        local Lhs, Rhs;
        if Inst.s then
            Lhs = Inst.A
        else
            Lhs = X[Inst.B]
        end
        if Inst.a then
            Rhs = Inst.C
        else
            Rhs = X[Inst.C]
        end
        if (Lhs < Rhs) == (Inst.A ~= 0) then z = z + x[z].f end;
        z = z + 1
        ]=]
	elseif (S == 25) then
		return [=[
        local Lhs, Rhs;
        if Inst.s then
            Lhs = Inst.A
        else
            Lhs = X[Inst.B]
        end
        if Inst.a then
            Rhs = Inst.C
        else
            Rhs = X[Inst.C]
        end
        if (Lhs <= Rhs) == (Inst.A ~= 0) then z = z + x[z].f end;
        z = z + 1
        ]=]
	elseif (S == 26) then
		return [=[
        if (not X[Inst.A]) ~= (Inst.C ~= 0) then z = z + x[z].f end
        z = z + 1
        ]=]
	elseif (S == 27) then
		return [=[
        local A = Inst.A
        local B = Inst.B;
        if (not X[B]) ~= (Inst.C ~= 0) then
            X[A] = X[B]
            z = z + x[z].f
        end;
        z = z + 1
        ]=]
	elseif (S == 28) then
		return [=[
        local A = Inst.A;
        local B = Inst.B;
        local Params;
        if B == 0 then
            Params = Top - A;
        else
            Params = B - 1;
        end;
        local RetB = Pack(X[A](Unpack(X, A + 1, A + Params)))
        local RetNum = RetB.n;
        if C == 0 then
            Top = A + RetNum - 1;
        else
            RetNum = C - 1;
        end;
        Move(RetB, 1, RetNum, A, X)
        ]=]
	elseif (S == 29) then
		return [=[
        local A = Inst.A;
        local B = Inst.B;
        local Params;
        if B == 0 then
            Params = Top - A;
        else
            Params = B - 1;
        end;
        CloseLuaUpvalues(SenB, 0)
        return X[A](Unpack(X, A + 1, A + Params))
        ]=]
	elseif (S == 30) then
		return [=[
        local A = Inst.A;
        local b = Inst.B;
        if B == 0 then        
            b = Top - A + 1;
        else
            b = B - 1;
        end;
        CloseLuaUpvalues(SenB, 0)
        return Unpack(X, A, A + b - 1)
        ]=]
	elseif (S == 31) then
		return [=[
        local A = Inst.A;
        local Step = X[A + 2]
        local N = X[A] + Step;
        local Limit = X[A + 1]
        local Loops
        if Step == math.abs(Step) then
            Loops = N <= Limit;
        else
            Loops = N >= Limit;
        end;
        if Loops then
            X[A] = N;
            X[A + 3] = N;
            z = z + Inst.f;
        end;
        ]=]
	elseif (S == 32) then
		return [=[
        local A = Inst.A;
        local Init, Limit, Step;
        Init = tonumber(X[A])
        Limit = tonumber(X[A + 1])
        Step = tonumber(X[A + 2])
        X[A] = Init - Step;
        X[A + 1] = Limit;
        X[A + 2] = Step;
        z = z + Inst.f;
        ]=]
	elseif (S == 33) then
		return [=[
        local A = Inst.A;
        local Base = A + 3;
        local Vals = {X[A](X[A + 1], X[A + 2])}
        Move(Vals, 1, Inst.C, Base, X)
        if X[Base] ~= nil then
            X[A + 2] = X[Base]
            z = z + x[z].f;
        end;
        z = z + 1
        ]=]
	elseif (S == 34) then
		return [=[
        local A = Inst.A
        local C = Inst.C
        local b = Inst.B;
        local Tab = X[A]
        local Offset;
        if b == 0 then b = Top - A end
        if C == 0 then
            C = x[z].m;
            z = z + 1
        end;
        Offset = (C - 1) * FIELDS_PER_FLUSH
        Move(X, A + 1, A + b, Offset + 1, Tab)
        ]=]
	elseif (S == 35) then
		return [=[CloseLuaUpvalues(SenB, Inst.A)]=]
	elseif (S == 36) then
		return [=[
        local Sub = V[Inst.F]
        local Nups = Sub.n;
        local UvB;
        if Nups ~= 0 then
            UvB = CreateTbl(Nups - 1)
            for i = 1, Nups do
                local Pseudo = x[z + i - 1]
                if (Pseudo.S == 0) then
                    UvB[i - 1] = SenLuaUpvalue(SenB, Pseudo.B, X)
                elseif (Pseudo.S == 4) then
                    UvB[i - 1] = n[Pseudo.B]
                end;
            end;
            z = z + Nups
        end;
        X[Inst.A] = WrapState(Sub, Env, UvB)
        ]=]
	elseif (S == 37) then
		return [=[
        local A = Inst.A;
        local b = Inst.B;
        if (b == 0) then
            b = v.b;
            Top = A + b - 1;
        end;
        Move(v.B, 1, b, A, X)
        ]=]
	end
end;
return GetOpcodeCode
