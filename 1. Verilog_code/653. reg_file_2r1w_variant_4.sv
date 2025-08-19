//SystemVerilog
module reg_file_2r1w #(
    parameter WIDTH = 32,
    parameter DEPTH = 32
)(
    input clk,
    input rst_n,
    input [4:0]  ra1,
    output [WIDTH-1:0] rd1,
    input [4:0]  ra2,
    output [WIDTH-1:0] rd2,
    input [4:0]  wa,
    input we,
    input [WIDTH-1:0] wd,
    output reg valid_out
);

// Register array
reg [WIDTH-1:0] rf [0:DEPTH-1];

// Pipeline registers
reg [4:0] ra1_stage1, ra2_stage1;
reg [4:0] ra1_stage2, ra2_stage2;
reg [WIDTH-1:0] rd1_stage2, rd2_stage2;
reg valid_stage1, valid_stage2;

// Write operation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < DEPTH; i++) begin
            rf[i] <= '0;
        end
    end else if (we) begin
        rf[wa] <= wd;
    end
end

// Stage 1: Address capture
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ra1_stage1 <= '0;
        ra2_stage1 <= '0;
        valid_stage1 <= 1'b0;
    end else begin
        ra1_stage1 <= ra1;
        ra2_stage1 <= ra2;
        valid_stage1 <= 1'b1;
    end
end

// Stage 2: Read operation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ra1_stage2 <= '0;
        ra2_stage2 <= '0;
        rd1_stage2 <= '0;
        rd2_stage2 <= '0;
        valid_stage2 <= 1'b0;
    end else begin
        ra1_stage2 <= ra1_stage1;
        ra2_stage2 <= ra2_stage1;
        rd1_stage2 <= rf[ra1_stage1];
        rd2_stage2 <= rf[ra2_stage1];
        valid_stage2 <= valid_stage1;
    end
end

// Output assignment
assign rd1 = rd1_stage2;
assign rd2 = rd2_stage2;
assign valid_out = valid_stage2;

endmodule