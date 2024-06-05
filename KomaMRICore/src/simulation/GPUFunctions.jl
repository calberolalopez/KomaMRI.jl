const LOADED_BACKENDS = Ref{Vector{KA.GPU}}([])
const BACKEND = Ref{Union{KA.Backend,Nothing}}(nothing)

device_name(backend) = @error "device_name called with invalid backend type $(typeof(backend))"
isfunctional(::KA.CPU) = true
isfunctional(x) = false
print_devices(backend) = @error "print_devices called with invalid backend type $(typeof(backend))"
name(::KA.CPU) = "CPU"
set_device!(backend, val) = @error "set_device! called with invalid parameter types: '$(typeof(backend))', '$(typeof(val))'" 

"""
    get_backend(use_gpu)

Gets the simulation backend to use. If use_gpu=false or there are no available GPU backends, 
returns CPU(), else, returns the GPU backend (currently either CUDABackend(), MetalBackend(), 
ROCBackend(), or oneAPIBackend()).

The GPU package for the corresponding backend (CUDA.jl, Metal.jl, AMDGPU.jl, or oneAPI.jl) must be
loaded and functional, otherwise KomaMRI will default to using the CPU.

# Arguments
- 'use_gpu': ('::Bool') If true, attempt to use GPU and check for available backends

# Returns
- 'backend': (::KernelAbstractions.backend) The backend to use
"""
function get_backend(use_gpu::Bool)
    if !isnothing(BACKEND[]) return BACKEND[] end

    if !use_gpu
        BACKEND[] = KA.CPU()
        return BACKEND[]
    end

    if isempty(LOADED_BACKENDS[])
        @info """ 
          The GPU functionality is being called but no GPU backend is loaded 
          to access it. Add 'using CUDA / Metal / AMDGPU / oneAPI' to your 
          code. Defaulting back to the CPU. (No action is required if you want
          to run on the CPU).
        """ maxlog=1
        BACKEND[] = KA.CPU()
        return BACKEND[]
    end

    functional_gpu_backends = []
    for backend in LOADED_BACKENDS[]
        if isfunctional(backend)
            push!(functional_gpu_backends, backend)
        else
            @warn "Loaded backend $(name(backend)) is not functional" maxlog=1
        end
    end
    
    if length(functional_gpu_backends) == 1
        BACKEND[] = functional_gpu_backends[1]
        @info """Using  backend: '$(name(BACKEND[]))'"""  maxlog = 1
        return BACKEND[]
    elseif length(functional_gpu_backends) == 0
        @info """Defaulting back to the CPU. (No action is required if you want to run on the CPU). """ maxlog = 1
        BACKEND[] = KA.CPU()
        return BACKEND[]
    else
        # Will probably never get here
        @info """
          Multiple functional backends have been loaded and KomaMRI does not 
          know which one to use. Ensure that your code contains only one 'using' 
          statement for the GPU backend you wish to use. Defaulting back to the 
          CPU. (No action is required if you want to run on the CPU).
        """ maxlog = 1
        BACKEND[] = KA.CPU()
        return BACKEND[]
    end
end

"""
    print_devices()

Simple function to print available GPU devices 
"""
function print_devices()
    backend = get_backend(true)
    backend isa KA.GPU && print_devices(backend)
end