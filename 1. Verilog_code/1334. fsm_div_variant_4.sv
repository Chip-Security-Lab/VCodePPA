//SystemVerilog
module fsm_div #(parameter EVEN=4, ODD=5) (
    input clk, mode, rst_n,
    output reg clk_out
);
    reg [2:0] state;
    reg mode_r;
    
    // Register mode input to reduce input-to-register delay
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mode_r <= 1'b0;
        end else begin
            mode_r <= mode;
        end
    end
    
    // More efficient state and output calculation with asynchronous reset
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= 3'b000;
            clk_out <= 1'b0;
        end else begin
            // Optimized next state logic
            if (mode_r) begin
                state <= (state == (ODD-1)) ? 3'b000 : state + 1'b1;
                // Simplified comparison for ODD mode clock output
                clk_out <= (state < ODD/2) ? 1'b0 : 1'b1;
            end else begin
                state <= (state == (EVEN-1)) ? 3'b000 : state + 1'b1;
                // Simplified comparison for EVEN mode clock output
                clk_out <= (state < EVEN/2) ? 1'b0 : 1'b1;
            end
        end
    end
endmodule