module ManchesterDecoder (
    input clk_16x,
    input manchester_in,
    output reg [7:0] decoded_data,
    output reg valid
);
    reg [3:0] bit_counter;
    reg [15:0] shift_reg;
    always @(posedge clk_16x) begin
        shift_reg <= {shift_reg[14:0], manchester_in};
        if (shift_reg[15:8] == 8'b01010101) begin
            decoded_data <= shift_reg[7:0];
            valid <= 1;
            bit_counter <= 0;
        end else begin
            valid <= 0;
            bit_counter <= (bit_counter == 15) ? 0 : bit_counter + 1;
        end
    end
endmodule
