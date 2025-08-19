//SystemVerilog
module clk_gate_addr #(parameter AW=2) (
    input clk, en,
    input [AW-1:0] addr,
    output reg [2**AW-1:0] decode
);
    // Pipeline register for intermediate result
    reg [AW-1:0] addr_reg;
    reg en_reg;
    
    // Combined pipeline stages in a single always block
    always @(posedge clk) begin
        // First pipeline stage: register inputs
        addr_reg <= addr;
        en_reg <= en;
        
        // Second pipeline stage: perform decode operation using registered values
        decode <= en_reg ? (1'b1 << addr_reg) : {2**AW{1'b0}};
    end
endmodule