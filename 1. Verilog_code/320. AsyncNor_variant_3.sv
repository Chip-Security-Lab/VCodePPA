//SystemVerilog
module AsyncNor(input clk, rst, a, b, output reg y);
    // Internal signals for input registration
    reg a_reg, b_reg;
    wire nor_result;
    
    // Move the register after the combinational logic (NOR gate)
    assign nor_result = ~(a | b);
    
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            y <= 0;
        end else begin
            y <= nor_result;
        end
    end
endmodule