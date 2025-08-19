//SystemVerilog
module loadable_div #(parameter W=4) (
    input clk, load, 
    input [W-1:0] div_val,
    output reg clk_out
);
    reg [W-1:0] cnt;
    wire cnt_is_zero;
    wire [W-1:0] next_cnt;
    reg clk_out_pre;
    
    // Buffered versions of cnt_is_zero signal to reduce fan-out
    reg cnt_is_zero_buf1, cnt_is_zero_buf2;
    
    // Determine next counter value with combinational logic
    assign cnt_is_zero = (cnt == 0);
    
    // Use buffered version for next_cnt calculation
    assign next_cnt = load ? div_val : 
                     (cnt_is_zero_buf1 ? div_val : cnt - 1);
    
    // Register update logic with buffered signals
    always @(posedge clk) begin
        // Buffer registers for high fan-out signal
        cnt_is_zero_buf1 <= cnt_is_zero;
        cnt_is_zero_buf2 <= cnt_is_zero;
        
        // Main counter and output logic
        cnt <= next_cnt;
        clk_out_pre <= load || !cnt_is_zero_buf2;
        clk_out <= clk_out_pre;
    end
endmodule