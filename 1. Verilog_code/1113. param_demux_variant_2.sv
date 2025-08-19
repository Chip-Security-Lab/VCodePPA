//SystemVerilog
// Top-level parameterized demux module with hierarchical structure

module param_demux #(
    parameter OUTPUT_COUNT = 8,         // Number of output lines
    parameter ADDR_WIDTH = 3            // Address width (log2 of outputs)
) (
    input wire data_input,              // Single data input
    input wire [ADDR_WIDTH-1:0] addr,   // Address selection
    output wire [OUTPUT_COUNT-1:0] out  // Multiple outputs
);

    // Internal one-hot decoded signal
    wire [OUTPUT_COUNT-1:0] one_hot_decode;

    // One-hot decoder submodule instance
    one_hot_decoder #(
        .OUTPUT_COUNT(OUTPUT_COUNT),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_one_hot_decoder (
        .addr(addr),
        .one_hot_out(one_hot_decode)
    );

    // Data distribution submodule instance
    demux_data_driver #(
        .OUTPUT_COUNT(OUTPUT_COUNT)
    ) u_demux_data_driver (
        .data_in(data_input),
        .one_hot_sel(one_hot_decode),
        .data_out(out)
    );

endmodule

// --------------------------------------------------------------
// One-hot decoder: Converts address value to one-hot code output
// --------------------------------------------------------------
module one_hot_decoder #(
    parameter OUTPUT_COUNT = 8,
    parameter ADDR_WIDTH = 3
) (
    input wire [ADDR_WIDTH-1:0] addr,
    output wire [OUTPUT_COUNT-1:0] one_hot_out
);
    // Internal signals for subtraction and comparison
    wire [ADDR_WIDTH-1:0] addr_zero = {ADDR_WIDTH{1'b0}};
    wire [ADDR_WIDTH-1:0] addr_invert [OUTPUT_COUNT-1:0];
    wire [ADDR_WIDTH-1:0] addr_sub_result [OUTPUT_COUNT-1:0];
    wire [ADDR_WIDTH-1:0] one_hot_check [OUTPUT_COUNT-1:0];

    genvar i;
    generate
        for (i = 0; i < OUTPUT_COUNT; i = i + 1) begin : gen_one_hot
            // Invert the addr for two's complement addition
            assign addr_invert[i] = ~addr;
            // Subtract addr from current index using two's complement addition
            // result = i - addr = i + (~addr) + 1
            assign addr_sub_result[i] = i[ADDR_WIDTH-1:0] + addr_invert[i] + 1'b1;
            // If result is zero, then addr == i
            assign one_hot_check[i] = addr_sub_result[i];
            assign one_hot_out[i] = (one_hot_check[i] == addr_zero) ? 1'b1 : 1'b0;
        end
    endgenerate
endmodule

// -------------------------------------------------------------------
// Demux data driver: Gating data input to output lines by one-hot sel
// -------------------------------------------------------------------
module demux_data_driver #(
    parameter OUTPUT_COUNT = 8
) (
    input wire data_in,
    input wire [OUTPUT_COUNT-1:0] one_hot_sel,
    output wire [OUTPUT_COUNT-1:0] data_out
);
    // Gate data_in to out[i] if one_hot_sel[i] is asserted
    genvar j;
    generate
        for (j = 0; j < OUTPUT_COUNT; j = j + 1) begin : gen_data_driver
            assign data_out[j] = data_in & one_hot_sel[j];
        end
    endgenerate
endmodule