//SystemVerilog
module Multiplier5(
    input clk,
    input valid,
    output reg ready,
    input [7:0] in_a, in_b,
    output reg [15:0] out_data,
    output reg out_valid
);
    // Sequential logic signals
    reg [7:0] a_reg, b_reg;
    reg [15:0] result_reg;
    reg busy;
    
    // Combinational logic signals
    wire [15:0] mult_result;
    wire next_busy;
    wire next_ready;
    wire next_out_valid;
    
    // Combinational logic for multiplication
    assign mult_result = a_reg * b_reg;
    
    // Combinational logic for control signals
    assign next_busy = valid && ready ? 1'b1 : 
                      busy ? 1'b0 : busy;
    
    assign next_ready = valid && ready ? 1'b0 : 
                       busy ? 1'b1 : ready;
    
    assign next_out_valid = busy ? 1'b1 : 1'b0;
    
    // Sequential logic - register updates
    always @(posedge clk) begin
        // Input registers
        if (valid && ready) begin
            a_reg <= in_a;
            b_reg <= in_b;
        end
        
        // Control signals
        busy <= next_busy;
        ready <= next_ready;
        out_valid <= next_out_valid;
        
        // Result register
        if (busy) begin
            result_reg <= mult_result;
        end
    end
    
    // Output assignment
    assign out_data = result_reg;
endmodule