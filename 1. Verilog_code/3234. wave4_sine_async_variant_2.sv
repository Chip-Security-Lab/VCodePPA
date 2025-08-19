//SystemVerilog
// SystemVerilog

// Top module: wave4_sine_async
// Instantiates the combinational lookup module and registers its output.
// This maintains the original module's interface and behavior.
module wave4_sine_async #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    output wire [DATA_WIDTH-1:0] wave_out
);

    // Wire to connect the combinational lookup module output
    wire [DATA_WIDTH-1:0] combinational_lookup_result;

    // Register to hold the final output
    reg [DATA_WIDTH-1:0] data_reg;

    // Instantiate the combinational lookup submodule
    sine_rom_lookup_comb #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) i_sine_rom_lookup_comb (
        .addr(addr),
        .lookup_data(combinational_lookup_result)
    );

    // Register the combinational lookup result
    // This preserves the original code's behavior of registering the lookup result
    // The output register updates asynchronously whenever the address changes.
    always @(addr) begin
        data_reg = combinational_lookup_result;
    end

    // Assign the registered value to the output port
    assign wave_out = data_reg;

endmodule


// Submodule: sine_rom_lookup_comb
// Contains the ROM data and the combinational multiplexer tree lookup logic.
// Performs an asynchronous lookup based on the address input.
module sine_rom_lookup_comb #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    output wire [DATA_WIDTH-1:0] lookup_data
);

    // ROM storage for waveform data
    // Marked for distributed RAM inference (LUTs)
    (* ram_style = "distributed" *) reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];

    // Initialize ROM with data
    // Original code initialized with simple arithmetic, replicating that here.
    // For a sine wave, this initial block would load sine values.
    initial begin
        integer i;
        for(i=0; i<(1<<ADDR_WIDTH); i=i+1) begin
            // Replicating original initialization logic: i % (1<<DATA_WIDTH)
            rom[i] = i % (1<<DATA_WIDTH);
            // For a true sine wave, you would load pre-calculated values here, e.g.:
            // rom[i] = $sin(i * 2 * $pi / (1<<ADDR_WIDTH)) * ((1<<(DATA_WIDTH-1))-1) + (1<<(DATA_WIDTH-1));
        end
    end

    // Wires for outputs of each stage of the multiplexer tree
    // stage_wires[s][m] is the output of MUX m in stage s
    // Stage s corresponds to address bit addr[s]
    // Stage 0 has (1 << (ADDR_WIDTH - 1)) MUXes
    // Stage ADDR_WIDTH-1 has 1 MUX
    wire [DATA_WIDTH-1:0] stage_wires [ADDR_WIDTH-1 : 0] [0 : (1<<(ADDR_WIDTH-1))-1];

    genvar gs, gm;

    // Stage 0: Select based on addr[0]
    // Inputs are directly from the ROM contents
    for (gm = 0; gm < (1<<(ADDR_WIDTH-1)); gm = gm + 1) begin : stage0_muxes
        assign stage_wires[0][gm] = addr[0] ? rom[2*gm+1] : rom[2*gm];
    end

    // Subsequent stages: Select based on addr[gs]
    // Inputs are from the previous stage's outputs
    for (gs = 1; gs < ADDR_WIDTH; gs = gs + 1) begin : subsequent_mux_stages
        // Number of MUXes in this stage
        localparam NUM_MUXES_IN_STAGE = (1 << (ADDR_WIDTH - 1 - gs));

        for (gm = 0; gm < NUM_MUXES_IN_STAGE; gm = gm + 1) begin : stage_muxes
            // Inputs are from the previous stage's outputs at indices 2*gm and 2*gm+1
            assign stage_wires[gs][gm] = addr[gs] ? stage_wires[gs-1][2*gm+1] : stage_wires[gs-1][2*gm];
        end
    end

    // The final output of the multiplexer tree is from the last stage (ADDR_WIDTH-1), MUX 0
    assign lookup_data = stage_wires[ADDR_WIDTH-1][0];

endmodule