//SystemVerilog
module delayed_output_buffer (
    input  wire       clk,
    input  wire [7:0] data_in,
    input  wire       load,
    output reg  [7:0] data_out,
    output reg        data_valid
);
    reg [7:0] buffer_stage1;
    reg [7:0] buffer_stage2;
    reg       valid_stage1;
    reg       valid_stage2;
    
    // First stage - capture inputs
    always @(posedge clk) begin
        buffer_stage1 <= load ? data_in : buffer_stage1;
        valid_stage1  <= load ? 1'b1 : 1'b0;
    end
    
    // Second stage - propagate to outputs
    always @(posedge clk) begin
        buffer_stage2 <= buffer_stage1;
        valid_stage2  <= valid_stage1;
        data_out      <= buffer_stage2;
        data_valid    <= valid_stage2;
    end
endmodule