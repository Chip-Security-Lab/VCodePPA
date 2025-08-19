//SystemVerilog
module irda_codec #(parameter DIV=16) (
    input clk, din,
    output reg dout
);
    // Main counter
    reg [7:0] pulse_cnt;
    
    // Buffer registers for high fanout signal
    reg [7:0] pulse_cnt_buf1;
    reg [7:0] pulse_cnt_buf2;
    
    // Buffered comparison results
    reg comp_threshold1;
    reg comp_threshold2;
    
    always @(posedge clk) begin
        // Update the main counter
        if(comp_threshold2) begin
            pulse_cnt <= 0;
        end
        else begin
            pulse_cnt <= pulse_cnt + 1;
        end
        
        // Buffer the counter value to reduce fanout
        pulse_cnt_buf1 <= pulse_cnt;
        pulse_cnt_buf2 <= pulse_cnt;
        
        // Pre-compute comparison results using distributed buffered signals
        comp_threshold1 <= (pulse_cnt_buf1 == (DIV*3/16));
        comp_threshold2 <= (pulse_cnt_buf2 == DIV);
        
        // Update output based on buffered comparison results
        if(comp_threshold1) begin
            dout <= !din;
        end
        else if(comp_threshold2) begin
            dout <= 1'b1;
        end
    end
endmodule