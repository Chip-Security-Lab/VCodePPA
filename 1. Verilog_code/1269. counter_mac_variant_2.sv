//SystemVerilog
module counter_mac #(parameter WIDTH=8) (
    input clk, rst,
    input [WIDTH-1:0] a, b,
    output reg [2*WIDTH-1:0] sum
);
    // Registered inputs
    reg [WIDTH-1:0] a_reg, b_reg;
    // Product calculation result
    wire [2*WIDTH-1:0] product;
    
    // Register input values
    always @(posedge clk) begin
        if (rst) begin
            a_reg <= {WIDTH{1'b0}};
            b_reg <= {WIDTH{1'b0}};
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // Combinational multiplication
    assign product = a_reg * b_reg;
    
    // Accumulation logic
    always @(posedge clk) begin
        if (rst)
            sum <= {(2*WIDTH){1'b0}};
        else
            sum <= sum + product;
    end
endmodule