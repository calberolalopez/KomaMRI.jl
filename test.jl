# Import packages
using PlotlyJS, KomaMRI

"""
For defining an EPI sequence
"""
function create_seq_epi(sys)
    B1 = sys.B1;
    durRF = π/2/(2π*γ*B1)
    EX = PulseDesigner.RF_hard(B1, durRF, sys; G=[0,0,0])
    N = 101
    FOV = 23e-2
    EPI = PulseDesigner.EPI(FOV, N, sys)
    TE = 30e-3
    d1 = TE-dur(EPI)/2-dur(EX)
    if d1 > 0 DELAY = Delay(d1) end
    seq = d1 > 0 ? EX + DELAY + EPI : EX + EPI
    seq.DEF["TE"] = round(d1 > 0 ? TE : TE - d1, digits=4)*1e3
    return seq
end

# Define scanner, object and sequence
sys = Scanner()
obj = brain_phantom2D()
seq = create_seq_epi(sys)

# Define simulator parameters
Δtgr, Δtrf = 1e-3, 1e-5

"""
For plotting user-defined sequence
"""
function plotseq(seq::Sequence)
    rf = rf_samples(seq)
    gx = gr_samples(seq, 1)
    gy = gr_samples(seq, 2)
    gz = gr_samples(seq, 3)
    adc = adc_samples(seq)
    prfa = scatter(; x=rf.t, y=(5000 .* abs.(samples_for_plot(rf.a, rf.onmask))), mode="lines+markers", name="rf.a")
    prfΔf = scatter(; x=rf.t, y=samples_for_plot(rf.Δf, rf.onmask), mode="lines+markers", name="rf.Δf")
    pgx = scatter(; x=gx.t, y=samples_for_plot(gx.a, gx.onmask), mode="lines+markers", name="GX")
    pgy = scatter(; x=gy.t, y=samples_for_plot(gy.a, gy.onmask), mode="lines+markers", name="GY")
    pgz = scatter(; x=gz.t, y=samples_for_plot(gz.a, gz.onmask), mode="lines+markers", name="GZ")
    padc = scatter(; x=adc.t, y=(.01 .* samples_for_plot(ones(length(adc.t)), adc.onmask)), mode="lines+markers", name="ADC")
    prfx = scatter(; x=rf.tx, y=(5000 .*abs.(rf.ax)), mode="markers", marker=attr(symbol="x"), name="RFcenter")
    display(plot([prfa; prfΔf; pgx; pgy; pgz; padc; prfx], Layout(title="User Defined Sequence")))
end
plotseq(seq)

"""
For plotting the simulated sequence
"""
function plotseq(seq::Sequence, Δtgr::Float64=1e-3, Δtrf::Float64=1e-5)
    sq = sequence_samples(seq, Δtgr, Δtrf)
    ix = sq.rfix[sq.rfix .!= 0]
    prfa = scatter(; x=sq.t, y=(5000 .* abs.(sq.rfa)), mode="lines+markers", name="RF")
    pgxa = scatter(; x=sq.t, y=sq.gxa, mode="lines+markers", name="GX")
    pgya = scatter(; x=sq.t, y=sq.gya, mode="lines+markers", name="GY")
    pgza = scatter(; x=sq.t, y=sq.gza, mode="lines+markers", name="GZ")
    padc = scatter(; x=sq.tadc, y=(.01 .* ones(length(sq.tadc))), mode="markers", name="ADC")
    prfx = scatter(; x=sq.t[ix], y=(5000 .* abs.(sq.rfa[ix])), mode="markers", marker=attr(symbol="x"), name="RFcenter")
    display(plot([prfa; pgxa; pgya; pgza; padc; prfx], Layout(title="Koma Simulated Sequence (All Points)")))
end
plotseq(seq, Δtgr, Δtrf)

"""
For plotting the simulated sequence but with masked on-events
"""
function plotonmaskseq(seq::Sequence, Δtgr::Float64=1e-3, Δtrf::Float64=1e-5)
    sq = sequence_samples(seq, Δtgr, Δtrf)
    ix = sq.rfix[sq.rfix .!= 0]
    prfa = scatter(; x=sq.t[sq.rf_onmask], y=(5000 .* abs.(sq.rfa)[sq.rf_onmask]), mode="lines+markers", name="RF")
    pgxa = scatter(; x=sq.t[sq.gx_onmask], y=sq.gxa[sq.gx_onmask], mode="lines+markers", name="GX")
    pgya = scatter(; x=sq.t[sq.gy_onmask], y=sq.gya[sq.gy_onmask], mode="lines+markers", name="GY")
    pgza = scatter(; x=sq.t[sq.gz_onmask], y=sq.gza[sq.gz_onmask], mode="lines+markers", name="GZ")
    padc = scatter(; x=sq.tadc, y=(.01 .* ones(length(sq.tadc))), mode="markers", name="ADC")
    prfx = scatter(; x=sq.t[ix], y=(5000 .* abs.(sq.rfa[ix])), mode="markers", marker=attr(symbol="x"), name="RFcenter")
    display(plot([prfa; pgxa; pgya; pgza; padc; prfx], Layout(title="Koma Simulated Sequence (Masked Points when events are on)")))
end
plotonmaskseq(seq, Δtgr, Δtrf)

"""
For plotting the kspace of the simulated sequence
"""
function plotkspace(seq::Sequence, Δtgr::Float64=1e-3, Δtrf::Float64=1e-5)
    k = KomaMRICore.kspace(seq, Δtgr, Δtrf)
    p1 = scatter3d(; x=k.x, y=k.y, z=k.z, mode="lines", hoverinfo="skip", name="simu-samples")
    p2 = scatter3d(; x=k.x[k.adc_onmask], y=k.y[k.adc_onmask], z=k.z[k.adc_onmask], mode="markers", name="adc-samples")
    p3 = scatter3d(; x=[0.], y=[0.], z=[0.], marker=attr(symbol="cross",size=10,color="red", name="ko"))
    display(plot([p1; p2; p3], Layout(title="K-Space of the Simulated Sequence")))
end
plotkspace(seq, Δtgr, Δtrf)


"""
# Simulate for new simple simulation
sq = sequence_samples(seq, Δtgr, Δtrf)
t, Δt, rfa, rfΔf, gxa, gya, gza, rf_onmask, gx_onmask, gy_onmask, gz_onmask, adc_onmask, tadc, blk_ranges = sq.t, sq.Δt, sq.rfa, sq.rfΔf, sq.gxa, sq.gya, sq.gza, sq.rf_onmask, sq.gx_onmask, sq.gy_onmask, sq.gz_onmask, sq.adc_onmask, sq.tadc, sq.blk_ranges
magxy, magz, sig = komasim(seq, obj)
display(plot([scatter(;x=t, y=abs.([sum(magxy; dims=1)...]), mode="lines+markers", name="sum(magxy)"); scatter(;x=t, y=abs.(sig), mode="lines+markers", name="sig")], Layout(title="Raw-Signal of the New Simulator-Function")))

# Simulate for old simulation
simParams = KomaMRICore.default_sim_params()
simParams["return_type"] = "mat"
simParams["gpu"] = false
told = KomaMRICore.get_adc_sampling_times(seq)
sigold = simulate(obj, seq, sys; simParams)
display(plot([scatter(;x=told, y=abs.(sigold[:,1,1]), mode="lines+markers", name="old")], Layout(title="Raw-Signal of the Old Simulator-Function")))

# Compare new and old simulations
display(plot([scatter(;x=t[adc_onmask], y=abs.(sig[adc_onmask]), mode="lines+markers", name="new"); scatter(;x=told, y=abs.(sigold[:,1,1]), mode="lines+markers", name="old")], Layout(title="Comparison of the Raw-Signals")))

# Reconstruction
function recon(sig, seq; isnew=true)
    sigm = isnew ? reshape(sig, length(sig), 1, 1) : sig
    raw = signal_to_raw_data(sigm, seq)
    acqData = AcquisitionData(raw)
    acqData.traj[1].circular = false #Removing circular window
    acqData.traj[1].nodes = acqData.traj[1].nodes[1:2,:] ./ maximum(2*abs.(acqData.traj[1].nodes[:])) #Normalize k-space to -.5 to .5 for NUFFT
    Nx, Ny = raw.params["reconSize"][1:2]
    recParams = Dict{Symbol,Any}()
    recParams[:reconSize] = (Nx, Ny)
    recParams[:densityWeighting] = true
    rec = reconstruction(acqData, recParams)
    image3d  = reshape(rec.data, Nx, Ny, :)
    image2d = (abs.(image3d) * prod(size(image3d)[1:2]))[:,:,1]
    return image2d
end
image2d = recon(sig[adc_onmask], seq; isnew=true)
display(plot_image(image2d, zmin=minimum(image2d), zmax=maximum(image2d), title="Reconstruction for New Simulator-Function"))
image2dold = recon(sigold, seq; isnew=false)
display(plot_image(image2dold, zmin=minimum(image2dold), zmax=maximum(image2dold), title="Reconstruction for Old Simulator-Function"))


############################################################################################
### Comparison with JEMRIS #################################################################
############################################################################################
using PlotlyJS, KomaMRI, HDF5

# Define input objects
seq = read_seq(joinpath(dirname(dirname(pathof(KomaMRI))), "KomaMRICore", "test", "test_files", "epi_100x100_TE100_FOV230.seq"))
obj = read_phantom_jemris(joinpath(dirname(dirname(pathof(KomaMRI))), "KomaMRICore", "test", "test_files", "sphere_chemical_shift.h5"))
sys = Scanner()

# Plot the sequence
plot_seq(seq)
plotseq(seq)
plotseq(seq, Δtgr, Δtrf)

# Old Koma simulation
simParams = Dict{String, Any}("gpu"=>false, "Nthreads"=>1, "sim_method"=>KomaMRICore.Bloch(), "return_type"=>"mat")
sigold = (simulate(obj, seq, sys; simParams) / prod(size(obj)))[:,1,1]
told = KomaMRICore.get_adc_sampling_times(seq)

# New Koma simulation
sq = sequence_samples(seq, Δtgr, Δtrf)
t, Δt, rfa, rfΔf, gxa, gya, gza, rf_onmask, gx_onmask, gy_onmask, gz_onmask, adc_onmask, tadc, blk_ranges = sq.t, sq.Δt, sq.rfa, sq.rfΔf, sq.gxa, sq.gya, sq.gza, sq.rf_onmask, sq.gx_onmask, sq.gy_onmask, sq.gz_onmask, sq.adc_onmask, sq.tadc, sq.blk_ranges
magxy, magz, sig = komasim(seq, obj)
signew = sig[adc_onmask] / prod(size(obj))
tnew = t[adc_onmask]

# Jemris ground-true data
sigjem = h5open(joinpath(dirname(dirname(pathof(KomaMRI))), "KomaMRICore", "test", "test_files", "jemris_signals_epi_sphere_cs.h5"))["/signal/channels/00"]
sigjem = sigjem[1,:] + 1im*sigjem[2,:]
sigjem = sigjem[:]

# Compare signals in plots
display(plot([scatter(; y=abs.(sigold), mode="lines+markers", name="old"); scatter(; y=abs.(signew), mode="lines+markers", name="new");], Layout(title="Comparison of the Raw-Signals")))
display(plot([scatter(; y=abs.(sigjem), mode="lines+markers", name="jem"); scatter(; y=abs.(sigold), mode="lines+markers", name="old");], Layout(title="Comparison of the Raw-Signals")))
display(plot([scatter(; y=abs.(sigjem), mode="lines+markers", name="jem"); scatter(; y=abs.(signew), mode="lines+markers", name="new");], Layout(title="Comparison of the Raw-Signals")))


############################################################################################
### Plot user defined events ###############################################################
############################################################################################

# Define the sequence
seq = create_seq_epi(sys)

# Plots for user-defined grs
function plotevent(gr::Grad)
    gr = KomaMRICore.event_samples(gr)
    pgr = scatter(; x=gr.t, y=gr.a, mode="lines+markers", name="GR")
    display(plot([pgr], Layout(title="Gradient")))
end
plotevent(seq[2].GR[1,1])
function plotgr(seq::Sequence)
    gr = KomaMRICore.gr_samples_for_plots(seq)
    pgx = scatter(; x=gr.tx, y=gr.ax, mode="lines+markers", name="GX")
    pgy = scatter(; x=gr.ty, y=gr.ay, mode="lines+markers", name="GY")
    pgz = scatter(; x=gr.tz, y=gr.az, mode="lines+markers", name="GZ")
    display(plot([pgx; pgy; pgz], Layout(title="Gradients of the Sequence")))
end
plotgr(seq)

# Plots for user-defined rfs
function plotevent(rf::RF)
    rf = KomaMRICore.event_samples(rf)
    prf = scatter(; x=rf.t, y=abs.(rf.a), mode="lines+markers", name="RF")
    display(plot([prf], Layout(title="RF")))
end
plotevent(seq[1].RF[1])
function plotrf(seq::Sequence)
    rf = KomaMRICore.rf_samples_for_plots(seq)
    prfa = scatter(; x=rf.t, y=abs.(rf.a), mode="lines+markers", name="rf.a")
    prfΔf = scatter(; x=rf.t, y=rf.Δf, mode="lines+markers", name="rf.Δf")
    display(plot([prfa; prfΔf], Layout(title="RFs of the Sequence")))
end
plotrf(seq + seq + seq)

# Plots for user-defined adcs
function plotevent(adc::ADC)
    adc = KomaMRICore.event_samples(adc)
    padc = scatter(; x=adc.t, y=ones(length(adc.t)), mode="lines+markers", name="ADC")
    display(plot([padc], Layout(title="ADC")))
end
plotevent(seq[5].ADC[1])
function plotadc(seq::Sequence)
    adc = KomaMRICore.adc_samples_for_plots(seq)
    padc = scatter(; x=adc.t, y=adc.a, mode="lines+markers", name="ADC")
    display(plot([padc], Layout(title="ADCs of the Sequence")))
end
plotadc(seq)
"""
