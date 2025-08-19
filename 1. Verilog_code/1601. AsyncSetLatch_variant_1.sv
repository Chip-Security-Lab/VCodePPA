//SystemVerilog
module AsyncSetLatch #(parameter W=8) (
    input clk, set,
    input [W-1:0] d,
    output reg [W-1:0] q
);

reg [W-1:0] d_stage1;
reg set_stage1;
reg [W-1:0] q_stage1;

// Stage 1: Input Register
always @(posedge clk) begin
    d_stage1 <= d;
    set_stage1 <= set;
end

// Stage 2: Computation
always @(posedge clk or posedge set_stage1) begin
    q_stage1 <= set_stage1 ? {W{1'b1}} : d_stage1;
end

// Stage 3: Output Register
always @(posedge clk) begin
    q <= q_stage1;
end

endmodule