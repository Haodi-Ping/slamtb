function [p,P_u,P_s,P_k,P_c] = invPinHole(u,s,k,c)

% INVPINHOLE Inverse pin-hole camera model, with radial distortion correction.
%   P = INVPINHOLE(U,S) gives the retroprojected point P of a pixel U at
%   depth S, from a canonical pin-hole camera, that is, with calibration
%   parameters
%     u0 = 0
%     v0 = 0
%     au = 1
%     av = 1
%   It uses reference frames {RDF,RD} (right-down-front for the 3D world
%   points and right-down for the pixel), according to this scheme:
%
%         / z (forward)
%        /
%       +------- x                 +------- u
%       |                          |
%       |      3D : P=[x;y;z]      |     image : U=[u;v]
%       | y                        | v
%
%   P = INVPINHOLE(U,S,K) allows the introduction of the camera's
%   calibration parameters:
%     K = [u0 v0 au av]'
%
%   P = INVPINHOLE(U,S,K,C) allows the introduction of the camera's radial
%   distortion correction parameters:
%     C = [c2 c4 c6 ...]'
%   so that the new pixel is corrected following the distortion equation:
%     U = U_D * (1 + K2*R^2 + K4*R^4 + ...)
%   with R^2 = sum(U_D.^2), being U_D the distorted pixel in the image
%   plane for a camera with unit focal length.
%
%   If U is a pixels matrix, INVPINHOLE(U,...) returns a points matrix P,
%   with these matrices defined as
%     U = [U1 ... Un];   Ui = [ui;vi]
%     P = [p1 ... pn];   pi = [xi;yi;zi]
%
%   [P,P_u,P_s,P_k,P_c] returns the Jacobians of P wrt U, S, K and C. It
%   only works for single pixels U=[u;v], and for distortion correction
%   vectors C of up to 3 parameters C=[c2;c4;c6]. See UNDISTORT for
%   information on longer distortion vectors.
%
%   See also RETRO, UNDISTORT, DEPIXELLISE, PINHOLE.

% (c) 2009 Joan Sola @ LAAS-CNRS


if nargout == 1 % only point

    switch nargin
        case 2
            p = retro(u,s);
        case 3
            p = retro(depixellise(u,k),s);
        case 4
            p = retro(undistort(depixellise(u,k),c),s);
    end


else % Jacobians

    if size(u,2) > 1
        error('Jacobians not available for multiple pixels')
    else

        switch nargin
            case 2
                [p, P_u, P_s] = retro(u,s);
                
            case 3
                [u1, U1_u, U1_k] = depixellise(u,k);
                [p, P_u1, P_s]   = retro(u1,s);
                P_u              = P_u1*U1_u;
                P_k              = P_u1*U1_k;
                
            case 4
                [u1, U1_u, U1_k]  = depixellise(u,k);
                [u2, U2_u1, U2_c] = undistort(u1,c);
                [p, P_u2, P_s]    = retro(u2,s);
                P_c               = P_u2*U2_c;
                P_k               = P_u2*U2_u1*U1_k;
                P_u               = P_u2*U2_u1*U1_u;
                
        end

    end

end

return

%% jac
syms u v s u0 v0 au av c2 c4 c6 real
U=[u;v];
k=[u0;v0;au;av];
c=[c2;c4;c6];

[p,P_u,P_s,P_k,P_c] = invPinHole(U,s,k,c);
% [p,P_u,P_s,P_k] = invPinHole(U,s,k);
% [p,P_u,P_s] = invPinHole(U,s);

simplify(P_u - jacobian(p,U))
simplify(P_s - jacobian(p,s))
simplify(P_k - jacobian(p,k))
simplify(P_c - jacobian(p,c))
