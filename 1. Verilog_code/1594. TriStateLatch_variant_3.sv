//SystemVerilog
module TriStateLatch #(parameter BITS=8) (
    input clk, oe,
    input [BITS-1:0] d,
    output [BITS-1:0] q
);
    reg [BITS-1:0] latched;
    reg [BITS-1:0] q_reg;
    
    always @(posedge clk) begin
        latched <= d;
        if (oe) begin
            q_reg <= latched;
        end else begin
            q_reg <= {BITS{1'bz}};
        end
    end
    
    assign q = q_reg;
endmodule