//SystemVerilog
module CascadeMux #(parameter DW=8) (
    input      [1:0]         sel1,
    input      [1:0]         sel2,
    input      [DW-1:0]      stage1 [3:0],
    input      [DW-1:0]      stage2 [3:0],
    output reg [DW-1:0]      out
);

reg [DW-1:0] stage1_mux_out;
reg [DW-1:0] stage2_mux_out;

// Stage 1 multiplexer
always @(*) begin
    case (sel1)
        2'd0: stage1_mux_out = stage1[0];
        2'd1: stage1_mux_out = stage1[1];
        2'd2: stage1_mux_out = stage1[2];
        2'd3: stage1_mux_out = stage1[3];
        default: stage1_mux_out = {DW{1'b0}};
    endcase
end

// Stage 2 multiplexer
always @(*) begin
    case (sel2)
        2'd0: stage2_mux_out = stage2[0];
        2'd1: stage2_mux_out = stage2[1];
        2'd2: stage2_mux_out = stage2[2];
        2'd3: stage2_mux_out = stage2[3];
        default: stage2_mux_out = {DW{1'b0}};
    endcase
end

// Output selection
always @(*) begin
    if (sel1[0])
        out = stage2_mux_out;
    else
        out = stage1_mux_out;
end

endmodule