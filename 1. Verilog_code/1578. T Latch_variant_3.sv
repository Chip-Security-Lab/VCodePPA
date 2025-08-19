//SystemVerilog
module t_latch (
    input wire t,        // Toggle input
    input wire enable,
    output reg q
);

    // Internal signals
    wire toggle_condition;
    reg next_state;
    
    // Combinational logic for toggle condition
    assign toggle_condition = enable & t;
    
    // State transition logic
    always @* begin
        next_state = toggle_condition ? ~q : q;
    end
    
    // State register
    always @(posedge toggle_condition) begin
        q <= next_state;
    end

endmodule