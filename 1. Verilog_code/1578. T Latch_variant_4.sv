//SystemVerilog
module t_latch (
    input wire clk,      // Clock input for synchronous operation
    input wire rst_n,    // Active-low reset
    input wire t,        // Toggle input
    input wire enable,   // Enable signal
    output reg q         // Output register
);

    // Internal signals
    reg next_state;
    wire toggle_condition;
    
    // Combinational logic for next state calculation
    assign toggle_condition = t & enable;
    
    // Next state logic
    always @* begin
        next_state = toggle_condition ? ~q : q;
    end
    
    // Sequential logic with reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;  // Reset state
        else
            q <= next_state;  // Update state on clock edge
    end

endmodule