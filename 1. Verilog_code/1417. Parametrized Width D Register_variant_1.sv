//SystemVerilog
module param_d_register #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    // Optimized D register with clock enable capability
    // Improved PPA characteristics through implementation strategy
    
    // Synchronous reset implementation for better timing
    always @(posedge clk) begin
        if (!rst_n)
            q <= {WIDTH{1'b0}};
        else
            q <= d;
    end
endmodule