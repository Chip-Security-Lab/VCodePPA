//SystemVerilog
module xor_crypt #(
    parameter KEY = 8'hA5
) (
    input           clk,
    input           rst_n,
    input  [7:0]    data_in,
    input           data_in_valid,
    output [7:0]    data_out,
    output          data_out_valid
);

//-----------------------------------------------------------------------------
// Pipeline Stage 1: Input Latching
//-----------------------------------------------------------------------------
reg [7:0]  data_stage1;
reg        valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage1  <= 8'b0;
        valid_stage1 <= 1'b0;
    end else begin
        data_stage1  <= data_in;
        valid_stage1 <= data_in_valid;
    end
end

//-----------------------------------------------------------------------------
// Pipeline Stage 2: XOR Operation
//-----------------------------------------------------------------------------
reg [7:0]  data_stage2;
reg        valid_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage2  <= 8'b0;
        valid_stage2 <= 1'b0;
    end else begin
        data_stage2  <= data_stage1 ^ KEY;
        valid_stage2 <= valid_stage1;
    end
end

//-----------------------------------------------------------------------------
// Pipeline Stage 3: Output Register for Improved Timing
//-----------------------------------------------------------------------------
reg [7:0]  data_stage3;
reg        valid_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage3  <= 8'b0;
        valid_stage3 <= 1'b0;
    end else begin
        data_stage3  <= data_stage2;
        valid_stage3 <= valid_stage2;
    end
end

//-----------------------------------------------------------------------------
// Output Assignments
//-----------------------------------------------------------------------------
assign data_out       = data_stage3;
assign data_out_valid = valid_stage3;

endmodule