module bin2thermometer #(parameter BIN_WIDTH = 3) (
    input      [BIN_WIDTH-1:0] bin_input,
    output reg [(2**BIN_WIDTH)-2:0] therm_output
);
    integer idx;
    always @(*) begin
        therm_output = {(2**BIN_WIDTH-1){1'b0}};
        for (idx = 0; idx < 2**BIN_WIDTH-1; idx = idx + 1) begin
            therm_output[idx] = (idx < bin_input) ? 1'b1 : 1'b0;
        end
    end
endmodule