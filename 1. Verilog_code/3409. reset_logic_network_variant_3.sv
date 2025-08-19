//SystemVerilog
//-----------------------------------------------------------------------------
// Title       : Reset Logic Network with Hierarchical Structure
// Project     : Reset Management System
// Description : Configurable reset signal processing network
// Standard    : IEEE 1364-2005 Verilog
//-----------------------------------------------------------------------------

module reset_logic_network (
    input  wire [3:0] reset_sources,
    input  wire [3:0] config_bits,
    output wire [3:0] reset_outputs
);
    
    wire [3:0] reset_pair_a;
    wire [3:0] reset_pair_b;
    
    // Generate the input pairs for each reset logic block
    reset_input_mapper u_input_mapper (
        .reset_sources (reset_sources),
        .reset_pair_a  (reset_pair_a),
        .reset_pair_b  (reset_pair_b)
    );
    
    // Generate the output signals using configurable logic
    reset_logic_processor u_logic_processor (
        .reset_pair_a  (reset_pair_a),
        .reset_pair_b  (reset_pair_b),
        .config_bits   (config_bits),
        .reset_outputs (reset_outputs)
    );
    
endmodule

//-----------------------------------------------------------------------------
// Reset Input Mapper - Creates input pairs for each reset logic block
//-----------------------------------------------------------------------------
module reset_input_mapper (
    input  wire [3:0] reset_sources,
    output wire [3:0] reset_pair_a,
    output wire [3:0] reset_pair_b
);
    
    // Map reset sources to appropriate pairs
    assign reset_pair_a[0] = reset_sources[0];
    assign reset_pair_b[0] = reset_sources[1];
    
    assign reset_pair_a[1] = reset_sources[1];
    assign reset_pair_b[1] = reset_sources[2];
    
    assign reset_pair_a[2] = reset_sources[2];
    assign reset_pair_b[2] = reset_sources[3];
    
    assign reset_pair_a[3] = reset_sources[3];
    assign reset_pair_b[3] = reset_sources[0];
    
endmodule

//-----------------------------------------------------------------------------
// Reset Logic Processor - Performs configurable AND/OR operations
//-----------------------------------------------------------------------------
module reset_logic_processor (
    input  wire [3:0] reset_pair_a,
    input  wire [3:0] reset_pair_b,
    input  wire [3:0] config_bits,
    output wire [3:0] reset_outputs
);
    
    // Generate reset outputs for all channels
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : reset_channel
            configurable_logic_cell u_logic_cell (
                .input_a     (reset_pair_a[i]),
                .input_b     (reset_pair_b[i]),
                .config_bit  (config_bits[i]),
                .logic_output(reset_outputs[i])
            );
        end
    endgenerate
    
endmodule

//-----------------------------------------------------------------------------
// Configurable Logic Cell - Single AND/OR operation based on configuration
//-----------------------------------------------------------------------------
module configurable_logic_cell (
    input  wire input_a,
    input  wire input_b,
    input  wire config_bit,
    output wire logic_output
);
    
    // Perform either AND or OR operation based on config_bit
    // config_bit = 1: AND operation
    // config_bit = 0: OR operation
    assign logic_output = config_bit ? (input_a & input_b) : (input_a | input_b);
    
endmodule