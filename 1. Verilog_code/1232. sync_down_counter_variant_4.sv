//SystemVerilog
module sync_down_counter #(parameter WIDTH = 8) (
    input wire clk, rst, enable,
    output reg [WIDTH-1:0] q_out
);
    // Internal signals for retiming
    reg enable_reg;
    reg rst_reg;
    reg [WIDTH-1:0] next_q;

    // Register the control signals to reduce input-to-register delay
    always @(posedge clk) begin
        enable_reg <= enable;
        rst_reg <= rst;
    end

    // Calculate next state combinationally using case statement
    always @(*) begin
        // Combine control signals into a control vector
        case ({rst_reg, enable_reg})
            2'b10,   // Reset is active (regardless of enable)
            2'b11:   // Reset is active and enable is active
                next_q = {WIDTH{1'b1}};  // Reset to all 1's
            
            2'b01:   // Reset is inactive, enable is active
                next_q = q_out - 1'b1;   // Count down
            
            2'b00:   // Reset is inactive, enable is inactive
                next_q = q_out;          // Hold current value
            
            default:  // For simulation completeness
                next_q = {WIDTH{1'b1}};
        endcase
    end

    // Update output register
    always @(posedge clk) begin
        q_out <= next_q;
    end
endmodule