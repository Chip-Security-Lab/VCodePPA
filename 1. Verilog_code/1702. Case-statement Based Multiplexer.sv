module case_mux_8way(
    input [3:0] bus0, bus1, bus2, bus3,
    input [3:0] bus4, bus5, bus6, bus7,
    input [2:0] sel,
    output reg [3:0] mux_out
);
    always @(*) begin
        case (sel)
            3'b000: mux_out = bus0;
            3'b001: mux_out = bus1;
            3'b010: mux_out = bus2;
            3'b011: mux_out = bus3;
            3'b100: mux_out = bus4;
            3'b101: mux_out = bus5;
            3'b110: mux_out = bus6;
            3'b111: mux_out = bus7;
        endcase
    end
endmodule