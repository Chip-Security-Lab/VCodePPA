//SystemVerilog
module Timer_AsyncPulse (
    input  logic clk, rst, start,
    output logic pulse
);
    logic [3:0] cnt;
    logic cnt_max;
    logic start_r;
    logic [3:0] cnt_plus_1;
    logic cnt_is_14;
    
    // Pipeline registers to cut critical path
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            start_r <= 1'b0;
        end
        else begin
            start_r <= start;
        end
    end
    
    // Pre-compute increment result to reduce critical path
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_plus_1 <= 4'd1;  // Initialize to 1 for first cycle
            cnt_is_14 <= 1'b0;
        end
        else begin
            cnt_plus_1 <= cnt + 4'd1;
            cnt_is_14 <= (cnt == 4'd14);
        end
    end
    
    // Main counter logic with reduced critical path
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 4'd0;
            cnt_max <= 1'b0;
            pulse <= 1'b0;
        end
        else begin
            if (start_r) begin
                if (cnt < 4'd15) begin
                    cnt <= cnt_plus_1;  // Use pre-computed value
                    cnt_max <= cnt_is_14;  // Use pre-computed comparison
                end
            end
            pulse <= cnt_max;  // Registered output
        end
    end
endmodule