//SystemVerilog
module shift_multiphase #(
    parameter WIDTH = 8
)(
    input  wire                  clk0,
    input  wire                  clk1,
    input  wire [WIDTH-1:0]      din,
    output reg  [WIDTH-1:0]      dout
);

//-----------------------------------------------------------------------------
// Pipeline Stage 1: Input Data Capture
//-----------------------------------------------------------------------------
reg [WIDTH-1:0] data_stage1_reg;

always @(posedge clk0) begin
    data_stage1_reg <= din;
end

//-----------------------------------------------------------------------------
// Pipeline Stage 2: Shift Operation
//-----------------------------------------------------------------------------
reg [WIDTH-1:0] data_stage2_reg;

always @(posedge clk0) begin
    data_stage2_reg <= data_stage1_reg << 2;
end

//-----------------------------------------------------------------------------
// Pipeline Stage 3: Clock Domain Crossing and Output Register
//-----------------------------------------------------------------------------
reg [WIDTH-1:0] data_stage3_reg;

always @(posedge clk1) begin
    data_stage3_reg <= data_stage2_reg;
end

//-----------------------------------------------------------------------------
// Output Assignment
//-----------------------------------------------------------------------------
always @(posedge clk1) begin
    dout <= data_stage3_reg;
end

endmodule