//SystemVerilog
module tristate_decoder(
    input [1:0] addr,
    input enable,
    output [3:0] select
);
    reg [3:0] select_reg;
    
    always @(*) begin
        select_reg = 4'bzzzz;
        if (enable) begin
            case (addr)
                2'b00: select_reg[0] = 1'b1;
                2'b01: select_reg[1] = 1'b1;
                2'b10: select_reg[2] = 1'b1;
                2'b11: select_reg[3] = 1'b1;
            endcase
        end
    end
    
    assign select = select_reg;
endmodule