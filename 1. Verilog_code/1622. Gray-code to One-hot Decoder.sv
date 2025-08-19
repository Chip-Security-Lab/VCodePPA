module gray_to_onehot (
    input [2:0] gray_in,
    output reg [7:0] onehot_out
);
    reg [2:0] binary;
    always @(*) begin
        binary[2] = gray_in[2];
        binary[1] = gray_in[2] ^ gray_in[1];
        binary[0] = gray_in[1] ^ gray_in[0];
        onehot_out = (8'd1 << binary);
    end
endmodule