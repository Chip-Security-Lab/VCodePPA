//SystemVerilog
module TriStateLatch #(parameter BITS=8) (
    input clk, 
    input oe,
    input [BITS-1:0] d,
    output reg [BITS-1:0] q
);

reg [BITS-1:0] latched_stage1;
reg [BITS-1:0] latched_stage2;
reg oe_stage1;
reg oe_stage2;

// Stage 1: Input Latch
always @(posedge clk) begin
    latched_stage1 <= d;
    oe_stage1 <= oe;
end

// Stage 2: Output Latch
always @(posedge clk) begin
    latched_stage2 <= latched_stage1;
    oe_stage2 <= oe_stage1;
end

// Stage 3: Output Driver
always @(*) begin
    if (oe_stage2) begin
        q = latched_stage2;
    end else begin
        q = {BITS{1'bz}};
    end
end

endmodule