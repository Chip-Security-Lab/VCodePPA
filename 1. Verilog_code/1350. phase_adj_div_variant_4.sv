//SystemVerilog
// SystemVerilog
module phase_adj_div #(parameter PHASE_STEP=2) (
    input clk, rst, adj_up,
    output reg clk_out
);
    // Phase and counter registers
    reg [7:0] phase, phase_next;
    reg [7:0] cnt;
    reg [7:0] cnt_buf1, cnt_buf2;
    
    // Pipelining registers for critical path
    reg phase_update_en;
    reg cnt_reset_r;
    reg [7:0] compare_value;
    
    // Pipeline stages for complex expressions
    reg [7:0] half_phase;
    reg [7:0] threshold;
    
    // First stage comparison result
    wire cnt_reset = (cnt == compare_value);
    
    always @(posedge clk) begin
        if (rst) begin
            // Reset all registers
            cnt <= 0;
            cnt_buf1 <= 0;
            cnt_buf2 <= 0;
            phase <= 0;
            phase_next <= 0;
            clk_out <= 0;
            phase_update_en <= 0;
            cnt_reset_r <= 0;
            compare_value <= 200;
            half_phase <= 0;
            threshold <= 100;
        end else begin
            // Pipeline stage 1: Calculate phase_next
            phase_update_en <= 1'b1;
            if (phase_update_en)
                phase_next <= adj_up ? phase + PHASE_STEP : phase - PHASE_STEP;
            
            // Pipeline stage 2: Update phase and derived values
            phase <= phase_next;
            half_phase <= phase_next / 2;
            compare_value <= 200 - phase_next;
            
            // Pipeline stage 3: Calculate comparison thresholds
            threshold <= 100 - half_phase;
            
            // Counter logic with registered reset condition
            cnt_reset_r <= cnt_reset;
            cnt <= cnt_reset_r ? 8'd0 : cnt + 8'd1;
            
            // Buffer the counter value to distribute fanout
            cnt_buf1 <= cnt;
            cnt_buf2 <= cnt_buf1;
            
            // Use buffered counter and threshold for output generation
            clk_out <= (cnt_buf2 < threshold);
        end
    end
endmodule