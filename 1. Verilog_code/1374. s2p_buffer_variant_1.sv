//SystemVerilog - IEEE 1364-2005
module s2p_buffer (
    input wire clk,
    input wire serial_in,
    input wire shift,
    input wire clear,
    output reg [7:0] parallel_out
);
    // Pipeline stage registers
    reg serial_in_stage1;
    reg shift_stage1;
    reg clear_stage1;
    reg [7:0] parallel_out_stage1;
    
    reg serial_in_stage2;
    reg shift_stage2;
    reg clear_stage2;
    reg [3:0] lower_half_stage2;
    reg [3:0] upper_half_stage2;
    
    // First pipeline stage - register inputs
    always @(posedge clk) begin
        serial_in_stage1 <= serial_in;
        shift_stage1 <= shift;
        clear_stage1 <= clear;
        parallel_out_stage1 <= parallel_out;
    end
    
    // Second pipeline stage - process stage 1 to stage 2 control signals
    always @(posedge clk) begin
        serial_in_stage2 <= serial_in_stage1;
        shift_stage2 <= shift_stage1;
        clear_stage2 <= clear_stage1;
    end
    
    // Process lower half data path
    always @(posedge clk) begin
        if (clear_stage1)
            lower_half_stage2 <= 4'b0000;
        else if (shift_stage1)
            lower_half_stage2 <= {parallel_out_stage1[2:0], serial_in_stage1};
        else
            lower_half_stage2 <= parallel_out_stage1[3:0];
    end
            
    // Process upper half data path
    always @(posedge clk) begin
        if (clear_stage1)
            upper_half_stage2 <= 4'b0000;
        else if (shift_stage1)
            upper_half_stage2 <= {parallel_out_stage1[6:4], parallel_out_stage1[3]};
        else
            upper_half_stage2 <= parallel_out_stage1[7:4];
    end
    
    // Final stage - combine results and output
    always @(posedge clk) begin
        if (clear_stage2)
            parallel_out <= 8'b0;
        else
            parallel_out <= {upper_half_stage2, lower_half_stage2};
    end
endmodule