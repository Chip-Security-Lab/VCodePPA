//SystemVerilog
module reg_file_2r1w #(
    parameter WIDTH = 32,
    parameter DEPTH = 32
)(
    input clk,
    input [4:0]  ra1,
    output [WIDTH-1:0] rd1,
    input [4:0]  ra2,
    output [WIDTH-1:0] rd2,
    input [4:0]  wa,
    input we,
    input [WIDTH-1:0] wd
);

// Register array with write enable
reg [WIDTH-1:0] rf [0:DEPTH-1];

// Pipeline stage 1: Address decode and read
reg [4:0] ra1_stage1;
reg [4:0] ra2_stage1;
reg [WIDTH-1:0] rd1_stage1;
reg [WIDTH-1:0] rd2_stage1;

// Pipeline stage 2: Read data register
reg [WIDTH-1:0] rd1_stage2;
reg [WIDTH-1:0] rd2_stage2;

// Write logic with early write enable decode
wire write_enable = we;
wire [4:0] write_addr = wa;
wire [WIDTH-1:0] write_data = wd;

// Stage 1: Address decode and read
always @(posedge clk) begin
    ra1_stage1 <= ra1;
    ra2_stage1 <= ra2;
    rd1_stage1 <= rf[ra1];
    rd2_stage1 <= rf[ra2];
end

// Stage 2: Read data register
always @(posedge clk) begin
    rd1_stage2 <= rd1_stage1;
    rd2_stage2 <= rd2_stage1;
end

// Write logic
always @(posedge clk) begin
    if (write_enable) begin
        rf[write_addr] <= write_data;
    end
end

// Output assignments
assign rd1 = rd1_stage2;
assign rd2 = rd2_stage2;

endmodule