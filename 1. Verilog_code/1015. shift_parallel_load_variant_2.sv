//SystemVerilog
module shift_parallel_load #(parameter DEPTH=4) (
    input wire clk,
    input wire load,
    input wire [7:0] pdata,
    output reg [7:0] sout
);

// Pipeline Stage 1: Input Capture
reg [7:0] pdata_stage1;
reg load_stage1;

// Pipeline Stage 2: Shift Register Update
reg [7:0] shift_reg_stage2;

// Pipeline Stage 3: Output Register Update
reg [7:0] shift_out_stage3;

//------------------------------------------------------------------------------
// Stage 1: Register input data and load signal
//------------------------------------------------------------------------------
always @(posedge clk) begin
    pdata_stage1 <= pdata;
    load_stage1  <= load;
end

//------------------------------------------------------------------------------
// Stage 2: Shift register logic
//------------------------------------------------------------------------------
always @(posedge clk) begin
    if (load_stage1)
        shift_reg_stage2 <= pdata_stage1;
    else
        shift_reg_stage2 <= {shift_reg_stage2[6:0], 1'b0};
end

//------------------------------------------------------------------------------
// Stage 3: Output register logic
//------------------------------------------------------------------------------
always @(posedge clk) begin
    shift_out_stage3 <= shift_reg_stage2;
end

//------------------------------------------------------------------------------
// Stage 4: Output assignment
//------------------------------------------------------------------------------
always @(posedge clk) begin
    sout <= shift_out_stage3;
end

endmodule