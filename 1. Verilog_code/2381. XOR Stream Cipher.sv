module xor_stream_cipher #(parameter KEY_WIDTH = 8, DATA_WIDTH = 16) (
    input wire clk, rst_n,
    input wire [KEY_WIDTH-1:0] key,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire valid_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);
    reg [KEY_WIDTH-1:0] key_reg;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            key_reg <= {KEY_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else if (valid_in) begin
            key_reg <= key ^ {key_reg[0], key_reg[KEY_WIDTH-1:1]};
            data_out <= data_in ^ {DATA_WIDTH/KEY_WIDTH{key_reg}};
            valid_out <= 1'b1;
        end else valid_out <= 1'b0;
    end
endmodule