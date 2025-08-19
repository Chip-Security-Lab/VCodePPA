module basic_rom (
    input [3:0] addr,
    output reg [7:0] data
);
    always @(*) begin
        case (addr)
            4'h0: data = 8'h12;
            4'h1: data = 8'h34;
            4'h2: data = 8'h56;
            4'h3: data = 8'h78;
            4'h4: data = 8'h9A;
            4'h5: data = 8'hBC;
            4'h6: data = 8'hDE;
            4'h7: data = 8'hF0;
            default: data = 8'h00;
        endcase
    end
endmodule
