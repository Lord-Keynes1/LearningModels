################################################################################
########## NHL_OPTIMIZATIONS.JL - solve value function optimization ############
################################################################################

using Distributions, FastGaussQuadrature, Interpolations, Optim

################################################################################
# Working life, no habits
function bellOpt(x::T, a::T, b::T, z::T, wmin::T,
   v_int::Interpolations.GriddedInterpolation, yn::Normal, k::Array, ρ::T,
   r::T, δ::T, σ::T, ξ::T) where T <: AbstractFloat

  function EVprime(w′::Float64, a=a, b=b, z=z, yn=yn, k=k, v_int=v_int, ρ=ρ, ξ=ξ)

    function EVp(y::Float64, w′=w′, v_int=v_int, yn=yn, a=a, b=b, z=z, ρ=ρ, ξ=ξ)
      dy = y - mean(yn)
      v_int[w′+exp(y), a+k[1]*dy, b+k[2]*dy, ρ*z+k[3]*dy]
    end

    (n, wgt) = gausshermite(10)
    evy = π^(-0.5)*sum( [wgt[i]*EVp(sqrt(2)*std(yn)*n[i] + mean(yn))
                                                          for i = 1:length(n)] )
    (1.0-ξ)*evy + ξ*v_int[w′, a, b, ρ*z]
  end

  Blmn(w′::Float64, x=x, r=r, δ=δ) = -( u(x-w′, σ) + δ*EVprime(r*w′) )

  optimum = Optim.optimize(Blmn, wmin/r, x + abs(wmin/r) + 1.)
  w′ = optimum.minimizer
  vopt = -(optimum.minimum)

  return w′, vopt
end

################################################################################

# Transition period, no habits
function bellOpt_TRANS(x::T, pension::T, wmin::T,
            v_int::Interpolations.GriddedInterpolation, r::T, δ::T, σ::T) where T <: AbstractFloat

  Blmn(w′) = -( u(x-w′, σ) + δ*v_int[r*w′, pension] )

  optimum = Optim.optimize(Blmn, wmin/r, x)
  w′ = optimum.minimizer
  vopt = -(optimum.minimum)

  return w′, vopt
end
