//SystemVerilog
module sync_fir_filter #(
    parameter DATA_W = 12,
    parameter TAP_W = 8,
    parameter TAPS = 4
)(
    input clk, rst,
    input [DATA_W-1:0] sample_in,
    input [TAP_W-1:0] coeffs [TAPS-1:0],
    output reg [DATA_W+TAP_W-1:0] filtered_out
);
    // Main delay line registers
    reg [DATA_W-1:0] delay_line [TAPS-1:0];
    
    // Buffered delay line for MAC operations (reduces fanout)
    reg [DATA_W-1:0] delay_line_buf1 [TAPS/2-1:0];
    reg [DATA_W-1:0] delay_line_buf2 [TAPS/2-1:0];
    
    // Separate accumulators for balanced load
    reg [DATA_W+TAP_W-1:0] acc_stage1 [1:0];
    reg [DATA_W+TAP_W-1:0] acc_final;
    
    // Pipeline registers for loop indices to reduce fanout
    reg [2:0] i_buf1, i_buf2;
    
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                delay_line[i] <= 0;
            end
            
            for (i = 0; i < TAPS/2; i = i + 1) begin
                delay_line_buf1[i] <= 0;
                delay_line_buf2[i] <= 0;
            end
            
            acc_stage1[0] <= 0;
            acc_stage1[1] <= 0;
            acc_final <= 0;
            filtered_out <= 0;
            i_buf1 <= 0;
            i_buf2 <= 0;
        end else begin
            // Shift samples through delay line with reduced fanout
            for (i = TAPS-1; i > 0; i = i - 1)
                delay_line[i] <= delay_line[i-1];
            delay_line[0] <= sample_in;
            
            // Buffer the delay line to reduce fanout
            for (i = 0; i < TAPS/2; i = i + 1) begin
                delay_line_buf1[i] <= delay_line[i];
                delay_line_buf2[i] <= delay_line[i + TAPS/2];
            end
            
            // Buffer loop index for use in multiple places
            i_buf1 <= 1;
            i_buf2 <= 2;
            
            // Split MAC operation to reduce critical path and balance loads
            acc_stage1[0] <= (delay_line_buf1[0] * coeffs[0]) + 
                            (delay_line_buf1[1] * coeffs[1]);
                            
            acc_stage1[1] <= (delay_line_buf2[0] * coeffs[2]) + 
                            (delay_line_buf2[1] * coeffs[3]);
            
            // Final accumulation stage
            acc_final <= acc_stage1[0] + acc_stage1[1];
            
            // Register the output
            filtered_out <= acc_final;
        end
    end
endmodule