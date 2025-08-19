module serial_range_detector(
    input wire clk, rst, data_bit, valid,
    input wire [7:0] lower, upper,
    output reg in_range
);
    reg [7:0] shift_reg;
    reg [2:0] bit_count;
    
    always @(posedge clk) begin
        if (rst) begin shift_reg <= 8'b0; bit_count <= 3'b0; in_range <= 1'b0; end
        else if (valid) begin
            shift_reg <= {shift_reg[6:0], data_bit};
            bit_count <= bit_count + 1;
            if (bit_count == 3'b111) // All 8 bits received
                in_range <= (shift_reg >= lower) && (shift_reg <= upper);
        end
    end
endmodule