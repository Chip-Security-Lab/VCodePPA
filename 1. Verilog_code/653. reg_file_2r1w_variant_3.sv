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

// Pipeline stage 1: Address decoding and register read
reg [4:0] ra1_stage1, ra2_stage1;
reg [WIDTH-1:0] wd_stage1;
reg [4:0] wa_stage1;
reg we_stage1;
reg valid_stage1;

// Pipeline stage 2: Register write and output
reg [WIDTH-1:0] rd1_stage2, rd2_stage2;
reg valid_stage2;

// Register file
reg [WIDTH-1:0] rf [0:DEPTH-1];

// Stage 1: Address decoding and register read
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ra1_stage1 <= 0;
        ra2_stage1 <= 0;
        wd_stage1 <= 0;
        wa_stage1 <= 0;
        we_stage1 <= 0;
        valid_stage1 <= 0;
    end else begin
        ra1_stage1 <= ra1;
        ra2_stage1 <= ra2;
        wd_stage1 <= wd;
        wa_stage1 <= wa;
        we_stage1 <= we;
        valid_stage1 <= 1'b1;
    end
end

// Stage 2: Register write and output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd1_stage2 <= 0;
        rd2_stage2 <= 0;
        valid_stage2 <= 0;
        valid_out <= 0;
    end else begin
        rd1_stage2 <= rf[ra1_stage1];
        rd2_stage2 <= rf[ra2_stage1];
        if (we_stage1) begin
            rf[wa_stage1] <= wd_stage1;
        end
        valid_stage2 <= valid_stage1;
        valid_out <= valid_stage2;
    end
end

// Output assignments
assign rd1 = rd1_stage2;
assign rd2 = rd2_stage2;

endmodule