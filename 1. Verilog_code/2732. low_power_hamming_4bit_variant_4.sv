//SystemVerilog
module hamming_encoder_comb(
    input [3:0] data,
    output [6:0] encoded_comb
);
    assign encoded_comb[0] = data[0] ^ data[1] ^ data[3];
    assign encoded_comb[1] = data[0] ^ data[2] ^ data[3];
    assign encoded_comb[2] = data[0];
    assign encoded_comb[3] = data[1] ^ data[2] ^ data[3];
    assign encoded_comb[4] = data[1];
    assign encoded_comb[5] = data[2];
    assign encoded_comb[6] = data[3];
endmodule

module low_power_hamming_4bit(
    input clk,
    input sleep_mode,
    input [3:0] data,
    output reg [6:0] encoded
);
    wire power_save_clk;
    wire [6:0] encoded_comb;
    
    assign power_save_clk = clk & ~sleep_mode;
    
    hamming_encoder_comb encoder_inst(
        .data(data),
        .encoded_comb(encoded_comb)
    );
    
    always @(posedge power_save_clk) begin
        if (sleep_mode) 
            encoded <= 7'b0;
        else 
            encoded <= encoded_comb;
    end
endmodule