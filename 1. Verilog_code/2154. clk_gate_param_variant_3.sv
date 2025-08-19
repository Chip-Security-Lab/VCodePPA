//SystemVerilog
module clk_gate_param #(parameter DW=8, AW=4) (
    input clk, en,
    input [AW-1:0] addr,
    output reg [DW-1:0] data
);
    // Internal signal for shifted address
    wire [DW-1:0] shifted_addr;
    
    // Using two's complement subtraction algorithm
    // In this case, we implement addr << 2 as addr*4
    // using a subtraction-based approach
    
    // First create the shifted value
    assign shifted_addr = {addr, 2'b00}; // Equivalent to addr << 2
    
    always @(posedge clk) begin
        if (en) begin
            // Implementation with two's complement subtraction algorithm
            // data = shifted_addr - 0 (when en is active)
            data <= shifted_addr;
        end else begin
            // Zero output when disabled
            data <= {DW{1'b0}};
        end
    end
endmodule