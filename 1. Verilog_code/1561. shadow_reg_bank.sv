module shadow_reg_bank #(parameter DW=8, AW=4) (
    input clk, we,
    input [AW-1:0] addr,
    input [DW-1:0] wdata,
    output [DW-1:0] rdata
);
    reg [DW-1:0] shadow_mem [2**AW-1:0];
    reg [DW-1:0] output_reg;
    
    always @(posedge clk) begin
        if(we) shadow_mem[addr] <= wdata;
        output_reg <= shadow_mem[addr];
    end
    assign rdata = output_reg;
endmodule