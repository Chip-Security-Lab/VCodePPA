//SystemVerilog
module lut_rom (
    input [3:0] addr,
    output reg [7:0] data
);
    always @(*) begin
        if (addr == 4'h0)
            data = 8'hA1;
        else if (addr == 4'h1)
            data = 8'hB2;
        else if (addr == 4'h2)
            data = 8'hC3;
        else if (addr == 4'h3)
            data = 8'hD4;
        else if (addr == 4'h4)
            data = 8'hE5;
        else if (addr == 4'h5)
            data = 8'hF6;
        else if (addr == 4'h6)
            data = 8'h07;
        else if (addr == 4'h7)
            data = 8'h18;
        else
            data = 8'h00;
    end
endmodule