//SystemVerilog
module sipo_register #(parameter N = 8) (
    input wire clk, rst, en,
    input wire s_in,
    output wire [N-1:0] p_out
);
    // Retimed shift register implementation
    reg [N-1:0] shift_register;
    reg s_in_reg;
    
    // First register the input to reduce input-to-register delay
    always @(negedge clk) begin
        if (rst)
            s_in_reg <= 1'b0;
        else if (en)
            s_in_reg <= s_in;
    end
    
    // Use two's complement addition to implement shifting operation
    // This is a clever implementation that achieves the same result as shifting
    wire [N-1:0] next_state;
    wire [N-1:0] complement_mask;
    wire [N-1:0] addition_result;
    
    // Create a mask based on the registered input
    assign complement_mask = {N{s_in_reg}};
    
    // Implement shift using addition of two's complement
    assign addition_result = shift_register + shift_register;
    assign next_state = addition_result ^ (complement_mask & {{(N-1){1'b0}}, 1'b1});
    
    // Update register with calculated next state
    always @(negedge clk) begin
        if (rst)
            shift_register <= {N{1'b0}};
        else if (en)
            shift_register <= next_state;
    end
    
    assign p_out = shift_register;
endmodule