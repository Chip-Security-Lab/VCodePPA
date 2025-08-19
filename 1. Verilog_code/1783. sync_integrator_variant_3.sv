//SystemVerilog
module sync_integrator #(
    parameter DATA_W = 16,
    parameter ACC_W = 24
)(
    input clk, rst, clear_acc,
    input [DATA_W-1:0] in_data,
    output reg [ACC_W-1:0] out_data
);

    reg [ACC_W-1:0] prev_out;
    wire [ACC_W-1:0] scaled_prev;
    wire [ACC_W-1:0] sum_result;
    
    // Buffer registers for high fanout signals
    reg [ACC_W-1:0] prev_out_buf1, prev_out_buf2;
    reg [ACC_W-1:0] sum_result_buf1, sum_result_buf2;
    
    // Scale previous output by 15/16 using conditional sum
    // Use buffered version of prev_out to reduce fanout
    assign scaled_prev = (prev_out_buf1 >> 1) + (prev_out_buf2 >> 2) + (prev_out_buf1 >> 3) + (prev_out_buf2 >> 4);
    
    // Add input to scaled previous output
    assign sum_result = in_data + scaled_prev;
    
    always @(posedge clk) begin
        if (rst | clear_acc) begin
            out_data <= 0;
            prev_out <= 0;
            // Reset buffer registers
            prev_out_buf1 <= 0;
            prev_out_buf2 <= 0;
            sum_result_buf1 <= 0;
            sum_result_buf2 <= 0;
        end else begin
            // Use buffered sum_result to reduce fanout
            out_data <= sum_result_buf1;
            prev_out <= sum_result_buf2;
            
            // Update buffer registers
            prev_out_buf1 <= prev_out;
            prev_out_buf2 <= prev_out;
            sum_result_buf1 <= sum_result;
            sum_result_buf2 <= sum_result;
        end
    end
endmodule