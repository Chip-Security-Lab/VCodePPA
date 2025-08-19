//SystemVerilog
module gray_to_onehot (
    input [2:0] gray_in,
    output reg [7:0] onehot_out
);
    wire [2:0] binary;
    
    assign binary[2] = gray_in[2];
    assign binary[1] = gray_in[2] ^ gray_in[1];
    assign binary[0] = gray_in[1] ^ gray_in[0];
    
    always @(*) begin
        if (binary == 3'b000)
            onehot_out = 8'b00000001;
        else if (binary == 3'b001)
            onehot_out = 8'b00000010;
        else if (binary == 3'b010)
            onehot_out = 8'b00000100;
        else if (binary == 3'b011)
            onehot_out = 8'b00001000;
        else if (binary == 3'b100)
            onehot_out = 8'b00010000;
        else if (binary == 3'b101)
            onehot_out = 8'b00100000;
        else if (binary == 3'b110)
            onehot_out = 8'b01000000;
        else if (binary == 3'b111)
            onehot_out = 8'b10000000;
        else
            onehot_out = 8'b00000000;
    end
endmodule