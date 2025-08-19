//SystemVerilog
module Timer_AsyncPulse (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    output wire       pulse
);
    reg [3:0] cnt;
    reg       pulse_r;
    
    // Pre-compute the next count value to reduce critical path
    wire [3:0] next_cnt = (cnt < 4'd15) ? cnt + 4'd1 : cnt;
    
    // Registered pulse output for better timing
    assign pulse = pulse_r;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 4'd0;
            pulse_r <= 1'b0;
        end
        else begin
            // Simplified logic with better balanced paths
            if (start) begin
                cnt <= next_cnt;
            end
            
            // Register the pulse condition to reduce critical path
            pulse_r <= (next_cnt == 4'd15) & start;
        end
    end
endmodule