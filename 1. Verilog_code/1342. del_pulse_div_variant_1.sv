//SystemVerilog
module del_pulse_div #(parameter N=3) (
    input wire clk,
    input wire rst,
    output reg clk_out
);

    // Efficient counter implementation with early termination detection
    reg [2:0] cnt;
    wire cnt_at_max = (cnt == N-2); // Pre-compute the terminal condition
    wire cnt_will_max = (cnt == N-1);
    
    // Direct toggle control signal
    reg toggle_pending;
    
    // Simplified pipeline control
    reg pipeline_valid;
    
    // Counter with optimized comparison logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 3'b000;
            pipeline_valid <= 1'b0;
        end else begin
            pipeline_valid <= 1'b1;
            
            if (cnt_will_max) begin
                cnt <= 3'b000;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end

    // Toggle control with balanced path delay
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            toggle_pending <= 1'b0;
        end else begin
            // Compute toggle condition in parallel with counter
            toggle_pending <= pipeline_valid && cnt_will_max;
        end
    end

    // Output clock generation with simplified condition
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else if (toggle_pending) begin
            clk_out <= ~clk_out;
        end
    end

endmodule