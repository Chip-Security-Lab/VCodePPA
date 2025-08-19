//SystemVerilog
module clk_gate_param #(parameter DW=8, AW=4) (
    input clk, en,
    input [AW-1:0] addr,
    output [DW-1:0] data
);
    reg [AW-1:0] addr_reg;
    reg en_reg;
    reg [DW-1:0] data_reg;
    
    always @(posedge clk) begin
        addr_reg <= addr;
        en_reg <= en;
    end
    
    always @(posedge clk) begin
        if (en_reg) begin
            data_reg <= addr_reg << 2;
        end else begin
            data_reg <= {DW{1'b0}};
        end
    end
    
    assign data = data_reg;
endmodule