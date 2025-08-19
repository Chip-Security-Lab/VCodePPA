module lut_rom (
    input [3:0] addr,
    output reg [7:0] data
);
    always @(*) begin
        case (addr)
            4'h0: data = 8'hA1;
            4'h1: data = 8'hB2;
            4'h2: data = 8'hC3;
            4'h3: data = 8'hD4;
            4'h4: data = 8'hE5;
            4'h5: data = 8'hF6;
            4'h6: data = 8'h07;
            4'h7: data = 8'h18;
            default: data = 8'h00;
        endcase
    end
endmodule
