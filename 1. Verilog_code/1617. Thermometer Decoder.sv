module therm_decoder (
    input clock,
    input [2:0] binary_in,
    output reg [7:0] therm_out
);
    always @(posedge clock) begin
        case (binary_in)
            3'd0: therm_out <= 8'b00000000;
            3'd1: therm_out <= 8'b00000001;
            3'd2: therm_out <= 8'b00000011;
            3'd3: therm_out <= 8'b00000111;
            3'd4: therm_out <= 8'b00001111;
            3'd5: therm_out <= 8'b00011111;
            3'd6: therm_out <= 8'b00111111;
            3'd7: therm_out <= 8'b01111111;
        endcase
    end
endmodule