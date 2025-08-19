//SystemVerilog
module gray_to_onehot (
    input [2:0] gray_in,
    output reg [7:0] onehot_out
);
    reg [2:0] binary;
    
    always @(*) begin
        binary[2] = gray_in[2];
        binary[1] = gray_in[2] ^ gray_in[1];
        binary[0] = gray_in[1] ^ gray_in[0];
        
        case(binary)
            3'd0: onehot_out = 8'b00000001;
            3'd1: onehot_out = 8'b00000010;
            3'd2: onehot_out = 8'b00000100;
            3'd3: onehot_out = 8'b00001000;
            3'd4: onehot_out = 8'b00010000;
            3'd5: onehot_out = 8'b00100000;
            3'd6: onehot_out = 8'b01000000;
            3'd7: onehot_out = 8'b10000000;
            default: onehot_out = 8'b00000000;
        endcase
    end
endmodule