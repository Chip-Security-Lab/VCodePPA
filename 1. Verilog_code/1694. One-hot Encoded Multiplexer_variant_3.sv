//SystemVerilog
// LUT Submodule
module lut_subtractor #(
    parameter DWIDTH = 8,
    parameter LUT_SIZE = 256
)(
    input [DWIDTH-1:0] data_in,
    input [DWIDTH-1:0] lut_index,
    output [DWIDTH-1:0] sub_result
);
    reg [DWIDTH-1:0] lut [0:LUT_SIZE-1];
    
    initial begin
        integer i;
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            lut[i] = i - data_in;
        end
    end
    
    assign sub_result = lut[lut_index];
endmodule

// One-hot Mux Submodule
module onehot_mux #(
    parameter DWIDTH = 8,
    parameter INPUTS = 4
)(
    input [DWIDTH-1:0] data_in [0:INPUTS-1],
    input [INPUTS-1:0] select_onehot,
    output [DWIDTH-1:0] data_out
);
    wire [DWIDTH-1:0] mux_out [0:INPUTS-1];
    
    genvar k;
    generate
        for (k = 0; k < INPUTS; k = k + 1) begin : mux_gen
            assign mux_out[k] = select_onehot[k] ? data_in[k] : {DWIDTH{1'b0}};
        end
    endgenerate
    
    assign data_out = mux_out[0] | mux_out[1] | mux_out[2] | mux_out[3];
endmodule

// Top Module
module onehot_mux_with_lut_subtractor #(
    parameter DWIDTH = 8,
    parameter INPUTS = 4,
    parameter LUT_SIZE = 256
)(
    input [DWIDTH-1:0] data_in [0:INPUTS-1],
    input [INPUTS-1:0] select_onehot,
    output [DWIDTH-1:0] data_out
);
    wire [DWIDTH-1:0] sub_results [0:INPUTS-1];
    wire [DWIDTH-1:0] muxed_result;
    
    genvar i;
    generate
        for (i = 0; i < INPUTS; i = i + 1) begin : sub_gen
            lut_subtractor #(
                .DWIDTH(DWIDTH),
                .LUT_SIZE(LUT_SIZE)
            ) sub_inst (
                .data_in(data_in[i]),
                .lut_index(data_in[i]),
                .sub_result(sub_results[i])
            );
        end
    endgenerate
    
    onehot_mux #(
        .DWIDTH(DWIDTH),
        .INPUTS(INPUTS)
    ) mux_inst (
        .data_in(sub_results),
        .select_onehot(select_onehot),
        .data_out(muxed_result)
    );
    
    assign data_out = muxed_result;
endmodule