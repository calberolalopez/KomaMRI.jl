mutable struct FuncWrapper # Function wrapper so we can re-define anonymous functions in the Phantom
	f::Function
end

"""
    phantom = Phantom(name, x, y, z, ρ, T1, T2, T2s, Δw, Dλ1, Dλ2, Dθ, ux, uy, uz)

The Phantom struct.

# Arguments
- `name`: (`::String`) name of the Phantom
- `x`: (`::AbstractVector{T}`, `[m]`) vector of x-positions of the spins
- `y`: (`::AbstractVector{T}`, `[m]`) vector of y-positions of the spins
- `z`: (`::AbstractVector{T}`, `[m]`) vector of z-positions of the spins
- `ρ`: (`::AbstractVector{T}`) vector of proton density of the spins
- `T1`: (`::AbstractVector{T}`, `[s]`) vector of T1 parameters of the spins
- `T2`: (`::AbstractVector{T}`, `[s]`) vector of T2 parameters of the spins
- `T2s`: (`::AbstractVector{T}`, `[s]`) vector of T2s parameters of the spins
- `Δw`: (`::AbstractVector{T}`, `[rad/s]`) vector of off-resonance parameters of the spins
- `Dλ1`: (`::AbstractVector{T}`) vector of Dλ1 (diffusion) parameters of the spins
- `Dλ2`: (`::AbstractVector{T}`) vector of Dλ2 (diffusion) parameters of the spins
- `Dθ`: (`::AbstractVector{T}`) vector of Dθ (diffusion) parameters of the spins
- `ux`: (`::Vector{Function}`) displacement field in the x-axis
- `uy`: (`::Vector{Function}`) displacement field in the y-axis
- `uz`: (`::Vector{Function}`) displacement field in the z-axis

# Returns
- `phantom`: (`::Phantom`) Phantom struct
"""
 @with_kw mutable struct Phantom{T<:Real}
	name::String = "spins"
	x::AbstractVector{T}
	y::AbstractVector{T} =   zeros(size(x))
	z::AbstractVector{T} =   zeros(size(x))
	ρ::AbstractVector{T} =   ones(size(x))
	T1::AbstractVector{T} =  ones(size(x)) * 1_000_000
	T2::AbstractVector{T} =  ones(size(x)) * 1_000_000
	T2s::AbstractVector{T} = ones(size(x)) * 1_000_000
	#Off-resonance related
	Δw::AbstractVector{T} =  zeros(size(x))
	#χ::Vector{SusceptibilityModel}
	#Diffusion
	Dλ1::AbstractVector{T} = zeros(size(x))
	Dλ2::AbstractVector{T} = zeros(size(x))
	Dθ::AbstractVector{T} =  zeros(size(x))
	#Diff::Vector{DiffusionModel}  #Diffusion map
	#Motion
	ux::Vector{FuncWrapper} = [FuncWrapper((t)->0 .* t) for i in 1:length(x)]
	uy::Vector{FuncWrapper} = [FuncWrapper((t)->0 .* t) for i in 1:length(x)]
	uz::Vector{FuncWrapper} = [FuncWrapper((t)->0 .* t) for i in 1:length(x)]
end

# Phantom() = Phantom(name="spin",x=zeros(1,1))
size(x::Phantom) = size(x.ρ)
Base.length(x::Phantom) = length(x.ρ)

"""Separate object spins in a sub-group."""
Base.getindex(obj::Phantom, p::AbstractRange) = begin
	Phantom(name=obj.name,
			x=obj.x[p],
			y=obj.y[p],
			z=obj.z[p],
			ρ=obj.ρ[p],
			T1=obj.T1[p],
			T2=obj.T2[p],
			T2s=obj.T2s[p],
			Δw=obj.Δw[p],
			#Diff=obj.Diff[p], #TODO!
			Dλ1=obj.Dλ1[p],
			Dλ2=obj.Dλ2[p],
			Dθ=obj.Dθ[p],
			#Χ=obj.Χ[p], #TODO!
			ux=obj.ux[p],
			uy=obj.uy[p],
			uz=obj.uz[p]
			)
end
"""Separate object spins in a sub-group."""
Base.view(obj::Phantom, p::AbstractRange) = begin
	@views Phantom(name=obj.name,
			x=obj.x[p],
			y=obj.y[p],
			z=obj.z[p],
			ρ=obj.ρ[p],
			T1=obj.T1[p],
			T2=obj.T2[p],
			T2s=obj.T2s[p],
			Δw=obj.Δw[p],
			#Diff=obj.Diff[p], #TODO!
			Dλ1=obj.Dλ1[p],
			Dλ2=obj.Dλ2[p],
			Dθ=obj.Dθ[p],
			#Χ=obj.Χ[p], #TODO!
			ux=obj.ux[p],
			uy=obj.uy[p],
			uz=obj.uz[p]
			)
end

# Compartment enabling routines:
# Addition of compartments
+(s1::Phantom,s2::Phantom) =begin
	Phantom(name=s1.name*"+"*s2.name,
		x=[s1.x;s2.x],
		y=[s1.y;s2.y],
		z=[s1.z;s2.z],
		ρ=[s1.ρ;s2.ρ],
		T1=[s1.T1;s2.T1],
		T2=[s1.T2;s2.T2],
		T2s=[s1.T2s;s2.T2s],
		Δw=[s1.Δw;s2.Δw],
		#Diff=obj.Diff[p], #TODO!
		Dλ1=[s1.Dλ1;s2.Dλ1],
		Dλ2=[s1.Dλ2;s2.Dλ2],
		Dθ=[s1.Dθ;s2.Dθ],
		#Χ=obj.Χ[p], #TODO!
		ux=s1.ux,
		uy=s1.uy,
		uz=s1.uz
	)
end
#Fraction of compartments
*(α::Real,obj::Phantom) = begin
	Phantom(name=obj.name,
		x=obj.x,
		y=obj.y,
		z=obj.z,
		ρ=α*obj.ρ, #Only affects the proton density
		T1=obj.T1,
		T2=obj.T2,
		T2s=obj.T2s,
		Δw=obj.Δw,
		#Diff=obj.Diff[p], #TODO!
		Dλ1=obj.Dλ1,
		Dλ2=obj.Dλ2,
		Dθ=obj.Dθ,
		#Χ=obj.Χ[p], #TODO!
		ux=obj.ux,
		uy=obj.uy,
		uz=obj.uz
	)
end

# Movement related commands
# StartAt(s::Phantom,t0::Float64) = Phantom(s.name,s.x,s.y,s.ρ,s.T2,s.Δw,s.Dλ1,s.Dλ2,s.Dθ,(x,y,t)->s.ux(x,y,t.+t0),(x,y,t)->s.uy(x,y,t.+t0))
# FreezeAt(s::Phantom,t0::Float64) = Phantom(s.name*"STILL",s.x.+s.ux(s.x,s.y,t0),s.y.+s.uy(s.x,s.y,t0),s.ρ,s.T2,s.Δw,s.Dλ1,s.Dλ2,s.Dθ,(x,y,t)->0,(x,y,t)->0)

#TODO: jaw-pitch-roll, expand, contract, functions

# Getting maps
# get_DxDy2D(obj::Phantom) = begin
# 	P(i) = rotz(obj.Dθ[i])[1:2,1:2];
# 	D(i) = [obj.Dλ1[i] 0;0 obj.Dλ2[i]]
# 	nx = [1;0]; ny = [0;1]
# 	Dx = [nx'*P(i)'*D(i)*P(i)*nx for i=1:prod(size(obj.Dλ1))]
# 	Dy = [ny'*P(i)'*D(i)*P(i)*ny for i=1:prod(size(obj.Dλ1))]
# 	Dx, Dy
# end

"""
    phantom = heart_phantom(α=1, β=1, γ=1, fat_bool::Bool=false)

Heart-like LV phantom. The variable `α` is for streching, `β` for contraction, and `γ` for
rotation.

# Arguments
- `α`: (`::Real`, `=1`) streching parameter
- `β`: (`::Real`, `=1`) contraction parameter
- `γ`: (`::Real`, `=1`) rotation parameter
- `fat_bool`: (`::Bool`, `=false`) fat boolean parameter

# Returns
- `phantom`: (`::Phantom`) Heart-like LV phantom struct
"""
heart_phantom(α=1, β=1, γ=1, fat_bool::Bool=false) = begin
	#PARAMETERS
	FOV = 10e-2 #m Diameter ventricule
	N = 21
	Δxr = FOV/(N-1) #Aprox rec resolution, use Δx_pix and Δy_pix
	Ns = 50 #number of spins per voxel
	Δx = Δxr/sqrt(Ns) #spin separation
	#POSITIONS
	x = y = -FOV/2:Δx:FOV/2-Δx #spin coordinates
	x, y = x .+ y'*0, x*0 .+ y' #grid points
	#PHANTOM
	⚪(R) =  (x.^2 .+ y.^2 .<= R^2)*1. #Circle of radius R
	v = FOV/4 #m/s 1/16 th of the FOV during acquisition
	ωHR = 2π/1 #One heart-beat in one second

	# θ(t) = -π/4*γ*(sin.(ωHR*t).*(sin.(ωHR*t).>0)+0.25.*sin.(ωHR*t).*(sin.(ωHR*t).<0) )
	ux(x,y,t) = begin
		strech = 0 #α * v * (x.^2 .+ y.^2) / (FOV/2)^2 .* sign.(x)
		contract = - β * v * x / (FOV/2)  #expand
		rotate = - γ * v * y / (FOV/2)
		def = (strech .+ contract .+ rotate) .* sin.(ωHR*t)
	end
	uy(x,y,t) = begin
		strech = 0 #α * v * (x.^2 .+ y.^2) / (FOV/2)^2 .* sign.(y)
		contract = - β * v * y / (FOV/2)
		rotate = γ * v * x / (FOV/2)
		def = (strech .+ contract .+ rotate) .* sin.(ωHR*t)
	end
	# Water spins
	R = 9/10*FOV/2
	r = 6/11*FOV/2
	ring = ⚪(R) .- ⚪(r)
	ρ = ⚪(r) .+ 0.9*ring #proton density
	# Diffusion tensor model
	D = 2e-9 #Diffusion of free water m2/s
	D1, D2 = D, D/20
	Dλ1 = D1*⚪(R) #Diffusion map
	Dλ2 = D1*⚪(r) .+ D2*ring #Diffusion map
	Dθ =  atan.(x,-y) .* ring #Diffusion map
	T1 = (1400*⚪(r) .+ 1026*ring)*1e-3 #Myocardial T1
	T2 = ( 308*⚪(r) .+ 42*ring  )*1e-3 #T2 map [s]
	# Generating Phantoms
	heart = Phantom("LeftVentricle",x,y,ρ,T2,Dλ1,Dλ2,Dθ,ux,uy)
	# Fat spins
	ring2 = ⚪(FOV/2) .- ⚪(R) #outside fat layer
	ρ_fat = .5*ρ.*ring2
	Δw_fat = 2π*220*ring2 #fat should be dependant on B0
	T1_fat = 800*ring2*1e-3
	T2_fat = 120*ring2*1e-3 #T2 map [s]
	fat = Phantom("fat",x,y,ρ_fat,T2_fat,Δw_fat)
	#Resulting phantom
	obj = fat_bool ? heart + fat : heart #concatenating spins
end


"""
    phantom = brain_phantom2D(;axis="axial", ss=4)

Creates a two-dimentional brain phantom struct.

# References
- B. Aubert-Broche, D.L. Collins, A.C. Evans: "A new improved version of the realistic
    digital brain phantom" NeuroImage, in review - 2006
- B. Aubert-Broche, M. Griffin, G.B. Pike, A.C. Evans and D.L. Collins: "20 new digital
    brain phantoms for creation of validation image data bases" IEEE TMI, in review - 2006
- https://brainweb.bic.mni.mcgill.ca/brainweb

# Keywords
- `axis`: (`::String`, `="axial"`, opts=[`"axial"`]) orientation of the phantom
- `ss`: (`::Real`, `=4`) subsampling parameter in all axis

# Returns
- `phantom`: (`::Phantom`) 2D Phantom struct

# Examples
```julia-repl
julia> obj = brain_phantom2D()

julia> plot_phantom_map(obj, :ρ)
```
"""
function brain_phantom2D(;axis="axial", ss=4)
    path = @__DIR__
    data = MAT.matread(path*"/phantom/brain2D.mat")

    class = data[axis][1:ss:end,1:ss:end]
    Δx = .5e-3*ss
    M, N = size(class)
    FOVx = (M-1)*Δx #[m]
    FOVy = (N-1)*Δx #[m]
    x = -FOVx/2:Δx:FOVx/2 #spin coordinates
    y = -FOVy/2:Δx:FOVy/2 #spin coordinates
    x, y = x .+ y'*0, x*0 .+ y' #grid points

    T2 = (class.==23)*329 .+ #CSF
        (class.==46)*83 .+ #GM
        (class.==70)*70 .+ #WM
        (class.==93)*70 .+ #FAT1
        (class.==116)*47 .+ #MUSCLE
        (class.==139)*329 .+ #SKIN/MUSCLE
        (class.==162)*0 .+ #SKULL
        (class.==185)*0 .+ #VESSELS
        (class.==209)*70 .+ #FAT2
        (class.==232)*329 .+ #DURA
        (class.==255)*70 #MARROW
    T2s = (class.==23)*58 .+ #CSF
        (class.==46)*69 .+ #GM
        (class.==70)*61 .+ #WM
        (class.==93)*58 .+ #FAT1
        (class.==116)*30 .+ #MUSCLE
        (class.==139)*58 .+ #SKIN/MUSCLE
        (class.==162)*0 .+ #SKULL
        (class.==185)*0 .+ #VESSELS
        (class.==209)*61 .+ #FAT2
        (class.==232)*58 .+ #DURA
        (class.==255)*61 .+#MARROW
        (class.==255)*70 #MARROW
    T1 = (class.==23)*2569 .+ #CSF
        (class.==46)*833 .+ #GM
        (class.==70)*500 .+ #WM
        (class.==93)*350 .+ #FAT1
        (class.==116)*900 .+ #MUSCLE
        (class.==139)*569 .+ #SKIN/MUSCLE
        (class.==162)*0 .+ #SKULL
        (class.==185)*0 .+ #VESSELS
        (class.==209)*500 .+ #FAT2
        (class.==232)*2569 .+ #DURA
        (class.==255)*500 #MARROW
    ρ = (class.==23)*1 .+ #CSF
        (class.==46)*.86 .+ #GM
        (class.==70)*.77 .+ #WM
        (class.==93)*1 .+ #FAT1
        (class.==116)*1 .+ #MUSCLE
        (class.==139)*.7 .+ #SKIN/MUSCLE
        (class.==162)*0 .+ #SKULL
        (class.==185)*0 .+ #VESSELS
        (class.==209)*.77 .+ #FAT2
        (class.==232)*1 .+ #DURA
        (class.==255)*.77 #MARROW
	Δw_fat = -220*2π
	Δw = (class.==93)*Δw_fat .+ #FAT1
		(class.==209)*Δw_fat    #FAT2
	T1 = T1*1e-3
	T2 = T2*1e-3
	T2s = T2s*1e-3
    phantom = Phantom{Float64}(name="brain2D_"*axis,
					  x=y[ρ.!=0],
					  y=x[ρ.!=0],
					  z=0*x[ρ.!=0],
					  ρ=ρ[ρ.!=0],
					  T1=T1[ρ.!=0],
					  T2=T2[ρ.!=0],
					  T2s=T2s[ρ.!=0],
					  Δw=Δw[ρ.!=0])
	phantom
end

"""
    phantom = brain_phantom3D(;ss=4)

Creates a three-dimentional brain phantom struct.

# References
- B. Aubert-Broche, D.L. Collins, A.C. Evans: "A new improved version of the realistic
    digital brain phantom" NeuroImage, in review - 2006
- B. Aubert-Broche, M. Griffin, G.B. Pike, A.C. Evans and D.L. Collins: "20 new digital
    brain phantoms for creation of validation image data bases" IEEE TMI, in review - 2006
- https://brainweb.bic.mni.mcgill.ca/brainweb

# Keywords
- `ss`: (`::Real`, `=4`) subsampling parameter in all axis

# Returns
- `phantom`: (`::Phantom`) 3D Phantom struct

# Examples
```julia-repl
julia> obj = brain_phantom3D()

julia> plot_phantom_map(obj, :ρ)
```
"""
function brain_phantom3D(;ss=4)
    path = @__DIR__
    data = MAT.matread(path*"/phantom/brain3D.mat")

    class = data["data"][1:ss:end,1:ss:end,160:ss:200]
    Δx = .5e-3*ss
    M, N, Z = size(class)
    FOVx = (M-1)*Δx #[m]
    FOVy = (N-1)*Δx #[m]
	FOVz = (Z-1)*Δx #[m]
    xx = reshape(-FOVx/2:Δx:FOVx/2,M,1,1) #spin coordinates
    yy = reshape(-FOVy/2:Δx:FOVy/2,1,N,1) #spin coordinates
	zz = reshape(-FOVz/2:Δx:FOVz/2,1,1,Z) #spin coordinates
    x = 1*xx .+ 0*yy .+ 0*zz
	y = 0*xx .+ 1*yy .+ 0*zz
	z = 0*xx .+ 0*yy .+ 1*zz

    T2 = (class.==23)*329 .+ #CSF
        (class.==46)*83 .+ #GM
        (class.==70)*70 .+ #WM
        (class.==93)*70 .+ #FAT1
        (class.==116)*47 .+ #MUSCLE
        (class.==139)*329 .+ #SKIN/MUSCLE
        (class.==162)*0 .+ #SKULL
        (class.==185)*0 .+ #VESSELS
        (class.==209)*70 .+ #FAT2
        (class.==232)*329 .+ #DURA
        (class.==255)*70 #MARROW
    T2s = (class.==23)*58 .+ #CSF
        (class.==46)*69 .+ #GM
        (class.==70)*61 .+ #WM
        (class.==93)*58 .+ #FAT1
        (class.==116)*30 .+ #MUSCLE
        (class.==139)*58 .+ #SKIN/MUSCLE
        (class.==162)*0 .+ #SKULL
        (class.==185)*0 .+ #VESSELS
        (class.==209)*61 .+ #FAT2
        (class.==232)*58 .+ #DURA
        (class.==255)*61 .+#MARROW
        (class.==255)*70 #MARROW
    T1 = (class.==23)*2569 .+ #CSF
        (class.==46)*833 .+ #GM
        (class.==70)*500 .+ #WM
        (class.==93)*350 .+ #FAT1
        (class.==116)*900 .+ #MUSCLE
        (class.==139)*569 .+ #SKIN/MUSCLE
        (class.==162)*0 .+ #SKULL
        (class.==185)*0 .+ #VESSELS
        (class.==209)*500 .+ #FAT2
        (class.==232)*2569 .+ #DURA
        (class.==255)*500 #MARROW
    ρ = (class.==23)*1 .+ #CSF
        (class.==46)*.86 .+ #GM
        (class.==70)*.77 .+ #WM
        (class.==93)*1 .+ #FAT1
        (class.==116)*1 .+ #MUSCLE
        (class.==139)*.7 .+ #SKIN/MUSCLE
        (class.==162)*0 .+ #SKULL
        (class.==185)*0 .+ #VESSELS
        (class.==209)*.77 .+ #FAT2
        (class.==232)*1 .+ #DURA
        (class.==255)*.77 #MARROW
	Δw_fat = -220*2π
	Δw = (class.==93)*Δw_fat .+ #FAT1
		(class.==209)*Δw_fat    #FAT2
	T1 = T1*1e-3
	T2 = T2*1e-3
	T2s = T2s*1e-3
    phantom = Phantom{Float64}(name ="brain3D",
							   x = y[ρ.!=0],
							   y = x[ρ.!=0],
							   z = z[ρ.!=0],
							   ρ = ρ[ρ.!=0],
							   T1 = T1[ρ.!=0],
							   T2 = T2[ρ.!=0],
							   T2s = T2s[ρ.!=0],
							   Δw = Δw[ρ.!=0])
	phantom
end


"""
phantom = read_phantom_file(filename)

Reads a (.phantom) file and creates a Phantom structure from it
"""
function read_phantom_file(filename)
    fid = HDF5.h5open(filename,"r")

	name    = read_attribute(fid,"Name")
    dims    = read_attribute(fid,"Dims")
    dynamic = Bool(read_attribute(fid,"Dynamic"))
    Ns      = read_attribute(fid,"Ns")
    version = read_attribute(fid,"Version")

    # --------------- Spin positions -----------------
    axis = HDF5.keys(fid["position"])
    if dims == length(axis)
        x = zeros(Ns)
        y = zeros(Ns)
        z = zeros(Ns)

        if "x" in axis
            x = read(fid["position/x"])
            if length(x) != Ns
                print("X vector length mismatch")   
            end
        end
        if "y" in axis
            y = read(fid["position/y"])
            if length(y) != Ns
                print("Y vector length mismatch")   
            end
        end
        if "z" in axis
            z = read(fid["position/z"])
            if length(z) != Ns
                print("Z vector length mismatch")   
            end
        end
    else
        print("Error: Phantom dimensions mismatch")
    end

    # ----------------- Contrast --------------------
    contrast = fid["contrast"]	

    # Rho
    rho = contrast["rho"]
    rho_type = read_attribute(rho,"type")

    if rho_type == "Explicit"
        rho_values = read(rho["values"])
		if Ns != length(rho_values)
			print("Error: rho vector dimensions mismatch")
		end

    elseif rho_type == "Default"
        rho_values = ones(Ns)

    elseif rho_type == "Indexed"
        index = read(rho["values"]) 
		if Ns == length(index)
			rho_table = read(rho["table"])
			Nrho = read_attribute(rho,"N")
			if Nrho == length(rho_table)
				rho_values = rho_table[index]
			else
				print("Error: rho table dimensions mismatch")
			end
		else
			print("Error: rho vector dimensions mismatch")
		end
    end


    # T1
    T1 = contrast["T1"]
    T1_type = read_attribute(T1, "type")

    if T1_type == "Explicit"
        T1_values = read(T1["values"])
		if Ns != length(T1_values)
			print("Error: T1 vector dimensions mismatch")
		end

    elseif T1_type == "Default"
        T1_values = ones(Ns)

    elseif T1_type == "Zero"
        T1_values = 1e-6 .* ones(Ns)

    elseif T1_type == "Indexed"
        index = read(T1["values"]) 
		if Ns == length(index)
			T1_table = read(T1["table"])
			NT1 = read_attribute(T1,"N")
			if NT1 == length(T1_table)
				T1_values = T1_table[index]
			else
				print("Error: T1 table dimensions mismatch")
			end
		else
			print("Error: T1 vector dimensions mismatch")
		end
    end

    # T2
    T2 = contrast["T2"]
    T2_type = read_attribute(T2, "type")

    if T2_type == "Explicit"
        T2_values = read(T2["values"])
		if Ns != length(T2_values)
			print("Error: T2 vector dimensions mismatch")
		end

    elseif  T2_type == "Default"
        T2_values = 0.1 .* ones(Ns)

    elseif  T2_type == "Inf"
        T2_values = ones(Ns)

    elseif  T2_type == "Indexed"
        index = read(T2["values"]) 
		if Ns == length(index)
			T2_table = read(T2["table"])
			NT2 = read_attribute(T2,"N")
			if NT2 == length(T2_table)
				T2_values = T2_table[index]
			else
				print("Error: T2 table dimensions mismatch")
			end
		else
			print("Error: T2 vector dimensions mismatch")
		end
    end

    # Δw
    Deltaw = contrast["Deltaw"]
    Deltaw_type = read_attribute(Deltaw, "type")

    if Deltaw_type == "Explicit"
        Deltaw_values = read(Deltaw["values"])
		if Ns != length(Deltaw_values)
			print("Error: Deltaw vector dimensions mismatch")
		end

    elseif  Deltaw_type == "Default"
        Deltaw_values = 0.1 .* ones(Ns)

    elseif  Deltaw_type == "Indexed"
        index = read(Deltaw["values"]) 
		if Ns == length(index)
			Deltaw_table = read(Deltaw["table"])
			NDeltaw = read_attribute(Deltaw,"N")
			if NDeltaw == length(Deltaw_table)
				Deltaw_values = Deltaw_table[index]
			else
				print("Error: Deltaw table dimensions mismatch")
			end
		else
			print("Error: Deltaw vector dimensions mismatch")
		end
    end

	phantom = Phantom{Float64}( name = name,
								x = x[:],
								y = y[:],
								z = z[:],
								ρ = rho_values[:],
								T1 = T1_values[:],
								T2 = T2_values[:],
								Δw = Deltaw_values[:])

    # ----------------- Diffusion --------------------
    # NOT IMPLEMENTED

    # ----------------- Motion --------------------
	if dynamic
		motion = fid["motion"]
		keys = HDF5.keys(motion)

		# Motion
		for key in keys
			if key != "segments"
				type = read_attribute(motion[key], "type")

				if type == "Explicit"
					values = read(motion[key]["values"])
					if Ns != length(values[:,1])
						print("Error: motion vector dimensions mismatch")
					end

				elseif type == "Indexed"
					index = read(motion[key]["values"]) 
					if Ns == length(index)
						table = read(motion[key]["table"])
						N = read_attribute(motion[key],"N")
						if N == length(table[:,1])
							values = table[index]
						else
							print("Error: motion table dimensions mismatch")
						end
					else
						print("Error: motion vector dimensions mismatch")
					end
				end
				
				# Here we should process motion values. First column is the motion model ID
				# and the rest of columns contain the values of the movement parameters for that model
				motion_models = values[:,1]
				β = Float32.(values[:,2:end])
				u = [FuncWrapper((t)->0) for i in 1:Ns]

				for i in 1:Ns
					# 1. Linear interpolation of one segment (Constant speed): u(t) = β0 + β1t
					if motion_models[i] == 1
						u[i].f = (t) -> β[i,1] .+ β[i,2] .* t
					end	

					# 2. Linear interpolation of K segments (...)
					# 3. Cubic interpolation of one segment (...)
					# 4. Cubic interpolation of K segments (...)
				end

				if 	   key == "motionx"
					phantom.ux = u
				elseif key == "motiony"
					phantom.uy = u
				elseif key == "motionz"
					phantom.uz = u
				end
			end
		end

		# Periodicity
		segments = motion["segments"]
		N = read_attribute(segments, "N")
		dur = read(segments["dur"])
	end

	close(fid)

	phantom
end


"""
phantom = read_nifti_file(folder; ss)

Reads a (.nii) file and creates a Phantom structure from it
"""
function read_nifti_file(folder; ss=1::Int)
	T1_path = folder*"T1map.nii.gz";
	T2_path = folder*"T2map.nii.gz";
	PD_path = folder*"PDmap.nii.gz";

	T1_ni = niread(T1_path);
	T2_ni = niread(T2_path);
	PD_ni = niread(PD_path);

	T1_data = T1_ni.raw
	T2_data = T2_ni.raw
	ρ = PD_ni.raw

	M, N, L = size(T1_data)

	# Subsampling
	T1_data = T1_data[1:ss:end,1:ss:end,1:ss:end]
	T2_data = T2_data[1:ss:end,1:ss:end,1:ss:end]
	ρ = ρ[1:ss:end,1:ss:end,1:ss:end]
	T2s_data = T2_data.+10

	# Clip outliers
	T1_percentile = percentile(T1_data[:],99)
	T1_data[T1_data.>=T1_percentile].= T1_percentile;

	T2_percentile = percentile(T2_data[:],99)
	T2_data[T2_data.>=T2_percentile].= T2_percentile;

	ρ_percentile = percentile(ρ[:],99)
	ρ[ρ.>=ρ_percentile].= ρ_percentile;

	T2s_percentile = percentile(T2s_data[:],99)
	T2s_data[T2s_data.>=T2s_percentile].= T2s_percentile;

	Δx = 1e-3*ss  # Each voxel is 1mm x 1mm x 1mm.
				  # Voxels have the same size in the three dimensions (cubic voxels)

	M, N, L = size(T1_data)


	println("Phantom size: $M x $N x $L elements")

	FOVx = (M-1)*Δx
	FOVy = (N-1)*Δx
	FOVz = (L-1)*Δx

	println("Phantom dimensions: ($FOVx x $FOVy x $FOVz) m")

	x = -FOVx/2:Δx:FOVx/2
	y = -FOVy/2:Δx:FOVy/2
	z = -FOVz/2:Δx:FOVz/2

	X,Y,Z = mgrid(x,y,z);

	Δw = zeros(M,N,L)

	# Convert miliseconds into seconds
	T1_data .*= 1e-3
	T2_data .*= 1e-3
	T2s_data .*= 1e-3

	phantom = Phantom{Float64}(name="nii_brain3D",
                          		x=X[ρ.!=0],
                          		y=Y[ρ.!=0],
                          		z=Z[ρ.!=0],
                          		ρ=ρ[ρ.!=0],
                          		T1=T1_data[ρ.!=0],
                          		T2=T2_data[ρ.!=0],
                          		T2s=T2s_data[ρ.!=0],
                          		Δw=Δw[ρ.!=0]
                          		)
	phantom
end
