//SystemVerilog
module DoubleBuffer #(parameter W=12) (
    input clk, load,
    input [W-1:0] data_in,
    output [W-1:0] data_out
);

reg [W-1:0] buf1_stage1, buf1_stage2;
reg [W-1:0] buf2_stage1, buf2_stage2;
reg load_stage1, load_stage2;

// Stage 1: Input and first buffer update
always @(posedge clk) begin
    load_stage1 <= load;
    buf1_stage1 <= data_in;
    buf2_stage1 <= buf1_stage1;
end

// Stage 2: Second buffer update and output
always @(posedge clk) begin
    load_stage2 <= load_stage1;
    if(load_stage2) begin
        buf1_stage2 <= buf1_stage1;
        buf2_stage2 <= buf2_stage1;
    end
end

assign data_out = buf2_stage2;

endmodule