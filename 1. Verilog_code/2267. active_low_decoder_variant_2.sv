//SystemVerilog
// Top level module
module active_low_decoder #(
    parameter ADDR_WIDTH = 3,
    parameter OUT_WIDTH = 8
)(
    input [ADDR_WIDTH-1:0] address,
    output [OUT_WIDTH-1:0] decode_n
);
    // Internal signals
    wire [OUT_WIDTH-1:0] default_state;
    wire [OUT_WIDTH-1:0] active_line;
    
    // Instantiate sub-modules
    default_generator #(
        .WIDTH(OUT_WIDTH)
    ) default_gen_inst (
        .default_out(default_state)
    );
    
    address_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) addr_decoder_inst (
        .address(address),
        .active_line(active_line)
    );
    
    output_composer #(
        .WIDTH(OUT_WIDTH)
    ) output_comp_inst (
        .default_state(default_state),
        .active_line(active_line),
        .decode_out(decode_n)
    );
    
endmodule

// Sub-module to generate default inactive state
module default_generator #(
    parameter WIDTH = 8
)(
    output [WIDTH-1:0] default_out
);
    assign default_out = {WIDTH{1'b1}}; // All outputs default to inactive (high)
endmodule

// Sub-module to decode address to one-hot format
module address_decoder #(
    parameter ADDR_WIDTH = 3,
    parameter OUT_WIDTH = 8
)(
    input [ADDR_WIDTH-1:0] address,
    output [OUT_WIDTH-1:0] active_line
);
    // Generate one-hot encoding with active low
    genvar i;
    generate
        for (i = 0; i < OUT_WIDTH; i = i + 1) begin : gen_decoder
            assign active_line[i] = (address == i) ? 1'b0 : 1'b1;
        end
    endgenerate
endmodule

// Sub-module to compose the final output
module output_composer #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] default_state,
    input [WIDTH-1:0] active_line,
    output [WIDTH-1:0] decode_out
);
    // Compose the final output based on active line
    assign decode_out = active_line;
endmodule