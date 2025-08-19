module bin_to_bcd #(
    parameter BIN_WIDTH = 8,
    parameter DIGITS = 3  // 输出BCD位数
)(
    input [BIN_WIDTH-1:0] binary_in,
    output reg [DIGITS*4-1:0] bcd_out
);
    integer i, j;
    reg [BIN_WIDTH+DIGITS*4-1:0] temp;
    
    always @(*) begin
        temp = {BIN_WIDTH+DIGITS*4{1'b0}};
        temp[BIN_WIDTH-1:0] = binary_in;
        
        for (i = 0; i < BIN_WIDTH; i = i + 1) begin
            for (j = 0; j < DIGITS; j = j + 1) begin
                if (temp[BIN_WIDTH+j*4 +: 4] > 4'd4)
                    temp[BIN_WIDTH+j*4 +: 4] = temp[BIN_WIDTH+j*4 +: 4] + 4'd3;
            end
            temp = temp << 1;
        end
        
        bcd_out = temp[BIN_WIDTH+DIGITS*4-1:BIN_WIDTH];
    end
endmodule