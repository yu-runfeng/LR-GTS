function TF = Is_Close(A, B, tol)
% IS_CLOSE A copy of isapprox() core function (for code generation)
% see documentation for isapprox()

abstol = tol;
reltol = tol;
TF = A == B | 0 <= max(abstol, reltol.*max(abs(A), abs(B))) - abs(A-B);
end
