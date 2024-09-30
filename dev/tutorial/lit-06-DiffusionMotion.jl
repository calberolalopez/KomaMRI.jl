# Diffusion MRI using the PGSE sequence

using KomaMRI # hide
using PlotlyJS # hide
using Random # hide

# The purpose of this tutorial is to showcase the simulation of diffusion-related effects. 
# For this, we are going to define a `Path <: Motion` to simulate the Brownian motion of spins.
# This is not the most efficient way of simulating diffusion, but it is a good way to understand the phenomenon.
# In particular, we will going to simulate isotropic diffusion, characterized by the Apparent Diffusion Coefficient (ADC).

# # Creating a phantom with isotropic diffusion

# First we will define a `Phantom` without motion containing `Nspins = 1_000` spins. The spins will have the same
# relaxation times `T1 = 1000 ms` and `T2 = 100 ms`, and will be placed at the origin.

Nspins = 10_000 
obj = Phantom(; 
    x  = zeros(Nspins),
    y  = zeros(Nspins),
    z  = zeros(Nspins),
    ρ  = ones(Nspins), 
    T1 = ones(Nspins) * 1000e-3,
    T2 = ones(Nspins) * 100e-3,
)

# Now we will define the Brownian motion of the spins using the [`Path`](@ref) motion definition.
# The motion will be defined by the displacements in the x, y, and z directions (`dx`, `dy`, and `dz`) 
# of the spins. The displacements will be generated by a random walk with mean square displacement 
# ``\mathbb{E}\left[x^{2}\right]=2D Δt``, where ``D`` is the diffusion coefficient
# and ``Δt`` is time step duration.

D = 2e-9               # Diffusion Coefficient of water in m^2/s
T = 100e-3             # Duration of the motion
Nt = 100               # Number of time steps
Δt = T / (Nt - 1)      # Time sep
Δr = sqrt.(2 * D * Δt) # √ Mean square displacement

# Random walk: Xt 
rng = MersenneTwister(1234) # Setting up the random seed
dx = cumsum([zeros(Nspins) Δr .* randn(rng, Nspins, Nt - 1)]; dims=2)
dy = cumsum([zeros(Nspins) Δr .* randn(rng, Nspins, Nt - 1)]; dims=2)
dz = cumsum([zeros(Nspins) Δr .* randn(rng, Nspins, Nt - 1)]; dims=2)

# Phantom definition
random_walk = Path(dx, dy, dz, TimeRange(0.0, T))
obj.motion = MotionList(random_walk)
p1 = plot_phantom_map(obj, :T1; intermediate_time_samples=Nt)

#md savefig(p1, "../assets/6-displacements.html") # hide
#jl display(p1)

#md # ```@raw html
#md # <center><object type="text/html" data="../../assets/6-displacements.html" style="width:80%; height:300px;"></object></center>
#md # ```

# The plot shows the random walk of spins due to diffusion, also known as Brownian motion.
# This motion was named after Robert Brown, who first described the phenomenon in 1827 while
# looking at pollen suspended in water under a microscope.

# # Pulse Gradient Spin Echo (PGSE) sequence

# The classical sequence used to measure diffusion is the pulse gradient spin echo (PGSE)
# introduced by Stejskal and Tanner in 1965. This sequence is characterized by the use of two diffusion
# gradients, placed right before and right after the inversion RF pulse. The duration of each gradient is
# defined by the δ parameter and the distance between the beginning of both gradients is described by the
# Δ parameter. In this tutorial square-shaped gradients will be used.
#
# First, we generate the RF pulses:
sys   = Scanner()
durRF = 1e-3 
B1    = (π / 2) / (2π * γ * durRF)
rf90  = PulseDesigner.RF_hard(B1, durRF, sys)
rf180 = (0.0 + 2im) * rf90

# Now we generate the gradients:
G = 30e-3            # Gradient amplitude
δ = 30e-3            # Duration of the gradient
Δ = durRF + δ        # Time between the two gradients
gx_diff = Grad(G, δ)

# Finally, we generate the ADC:
adc_dwell_time = 1e-6
adc = ADC(1, adc_dwell_time, durRF/2 - adc_dwell_time/2) # ADCs with N=1 are positioned at the center

# Obtaining the PGSE sequence:
seq = Sequence()
seq += rf90
seq += gx_diff
seq += rf180
seq += gx_diff
seq += adc
p2 = plot_seq(seq; show_adc=true) # Plotting the sequence 

#md savefig(p2, "../assets/6-pgse_sequence.html") # hide
#jl display(p2)

#md # ```@raw html
#md # <center><object type="text/html" data="../../assets/6-pgse_sequence.html" style="width:80%; height:300px;"></object></center>
#md # ```

# For the isotropic diffusion, the signal attenuation is given by the Stejskal-Tanner formula:
#
# ```math
# E = \exp\left(-b \cdot D\right)
# ```
#
# where \(b\) is the b-value, defined as:
#
# ```math
# b = \gamma^{2} \cdot G^{2} \cdot \delta^{2} \cdot \left(\Delta - \delta/3\right)
# ```
#
# where ``\gamma`` is the gyromagnetic ratio, ``G`` is the gradient amplitude, ``\delta`` is the gradient duration,
# and ``\Delta`` is the time between the two gradients.
function bvalue(seq)
    block, axis = 2, 1 # Gx from second block
    G = seq.GR[axis, block].A
    δ = seq.GR[axis, block].T
    Δ = dur(seq[1:2]) # Because there is no space in between
    b = (2π * γ * G * δ)^2 * (Δ - δ/3)
    return b * 1e-6
end
b = bvalue(seq) # bvalue in s/mm^2

# # Simulating the PGSE sequence
# To be able to quantify the ADC, we need to simulate the signal attenuation for different b-values.
# For this, we will scale the gradient amplitude of the sequence to obtain the desired b-value.
# We will store the sequences in a vector `seqs` and simulate the signal for each one of them.

seqs = Sequence[] # Vector of sequences
bvals = [0, 250, 500, 1000, 1500, 2000] # b-values in s/mm^2
for b_target in bvals
    gradient_scaling = sqrt(b_target / b)
    seq_b = gradient_scaling * seq
    push!(seqs, seq_b)
end
bvalue.(seqs)'

# To simulate, we will broadcast the `simulate` function over the sequences and store the signals in a vector `S`.
# The `Ref(x)` is used to avoid broadcasting the `obj` and `sys` arguments (they will remain constant for all `seqs`).

sim_params = KomaMRICore.default_sim_params()
sim_params["return_type"] = "mat"

signals = simulate.(Ref(obj), seqs, Ref(sys); sim_params)

Sb = [sb[1] for sb in signals] # Reshaping the simulated signals
bvals_si = bvals .* 1e6 # Convert b-values from s/mm^2 to s/m^2

E_simulated   = abs.(Sb) ./ abs.(Sb[1])
E_theoretical = exp.(-bvals_si .* D)

s_sim  = scatter(x=bvals, y=E_simulated,   name="Simulated") # hide
s_theo = scatter(x=bvals, y=E_theoretical, name="exp(-b D)") # hide
layout = Layout(title="PGSE Signal Attenuation E(b)", xaxis=attr(title="b-value [s/mm^2]")) # hide
p3 = plot([s_sim, s_theo], layout) # hide

#md savefig(p3, "../assets/6-pgse_signal_attenuation.html") # hide
#jl display(p3)

#md # ```@raw html
#md # <center><object type="text/html" data="../../assets/6-pgse_signal_attenuation.html" style="width:80%; height:300px;"></object></center>
#md # ```

# The plot shows the signal attenuation as a function of the b-value. The simulated signal attenuation
# matches the theoretical curve, showing the expected exponential decay with the b-value.