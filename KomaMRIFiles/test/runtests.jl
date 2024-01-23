using TestItems, TestItemRunner

@run_package_tests filter=ti->!(:skipci in ti.tags)&&(:files in ti.tags) #verbose=true

@testitem "Files" tags=[:files] begin
    using Suppressor

    # Test JEMRIS
    @testset "JEMRIS" begin
        path = @__DIR__
        obj = read_phantom_jemris(path*"/test_files/column1d.h5")
        @test obj.name == "column1d.h5"
    end

    # Test JEMRIS
    @testset "MRiLab" begin
        path = @__DIR__
        filename = path * "/test_files/brain_mrilab.mat"
        FRange_filename = path * "/test_files/FRange.mat" #Slab within slice thickness
        obj = read_phantom_MRiLab(filename; FRange_filename)
        @test obj.name == "brain_mrilab.mat"
    end

    # Test ReadPulseq
    @testset "ReadPulseq" begin
        path = @__DIR__
        seq = @suppress read_seq(path*"/test_files/epi.seq") #Pulseq v1.4.0, RF arbitrary
        @test seq.DEF["FileName"] == "epi.seq"
        @test seq.DEF["PulseqVersion"] ≈ 1004000

        seq = @suppress read_seq(path*"/test_files/spiral.seq") #Pulseq v1.4.0, RF arbitrary
        @test seq.DEF["FileName"] == "spiral.seq"
        @test seq.DEF["PulseqVersion"] ≈ 1004000

        seq = @suppress read_seq(path*"/test_files/epi_JEMRIS.seq") #Pulseq v1.2.1
        @test seq.DEF["FileName"] == "epi_JEMRIS.seq"
        @test seq.DEF["PulseqVersion"] ≈ 1002001

        seq = @suppress read_seq(path*"/test_files/radial_JEMRIS.seq") #Pulseq v1.2.1
        @test seq.DEF["FileName"] == "radial_JEMRIS.seq"
        @test seq.DEF["PulseqVersion"] ≈ 1002001

        # Test Pulseq compression-decompression
        shape = ones(100)
        num_samples, compressed_data = KomaMRIFiles.compress_shape(shape)
        shape2 = KomaMRIFiles.decompress_shape(num_samples, compressed_data)
        @test shape == shape2
    end

    # Test WritePulseq
    @testset "WritePulseq" begin

        # Temporal test results
        #seq_filename_head = "cine_gre"            # false = (seq_original ≈ seq_written)
        #seq_filename_head = "DEMO_gre"            # true  = (seq_original ≈ seq_written)
        #seq_filename_head = "DEMO_grep"           # true  = (seq_original ≈ seq_written)
        #seq_filename_head = "epi_label"           # false = (seq_original ≈ seq_written)
        #seq_filename_head = "epi_rs"              # Error after reading seq_written
        #seq_filename_head = "epi_se"              # true  = (seq_original ≈ seq_written)
        #seq_filename_head = "epi"                 # true  = (seq_original ≈ seq_written)
        #seq_filename_head = "epise_rs"            # false = (seq_original ≈ seq_written)
        #seq_filename_head = "external"            # true  = (seq_original ≈ seq_written)
        #seq_filename_head = "gre_rad"             # true  = (seq_original ≈ seq_written)
        #seq_filename_head = "spiral"              # true  = (seq_original ≈ seq_written)
        #seq_filename_head = "tabletop_tse_pulseq" # true  = (seq_original ≈ seq_written)

        path = @__DIR__
        test_folder = joinpath(@__DIR__, "test_files", "pulseq")

        # Test for some .seq files
        filenames = ["DEMO_gre", "DEMO_grep", "epi_se", "epi", "external", "gre_rad", "spiral", "tabletop_tse_pulseq"]
        #filenames = ["cine_gre", "epi_label", "epi_rs", "epise_rs"]
        for seq_filename_head in filenames
            seq_filename_head = seq_filename_head
            seq_original_filename = seq_filename_head * ".seq"
            seq_written_filename = seq_filename_head * "_written.seq"
            seq_original_file = joinpath(test_folder, seq_original_filename)
            seq_written_file = joinpath(test_folder, seq_written_filename)
            seq_original = @suppress read_seq(seq_original_file)
            write_seq(seq_original, seq_written_file)
            seq_written = @suppress read_seq(seq_written_file)
            rm(seq_written_file; force=true)
            @test seq_original ≈ seq_written
        end

    end
end
