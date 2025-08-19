module sbox_substitution #(parameter ADDR_WIDTH = 4, DATA_WIDTH = 8) (
    input wire clk, rst,
    input wire enable,
    input wire [ADDR_WIDTH-1:0] addr_in,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    reg [DATA_WIDTH-1:0] sbox [0:(1<<ADDR_WIDTH)-1];
    
    always @(posedge clk or posedge rst) begin
        if (rst) data_out <= 0;
        else if (enable) begin
            // Simple substitution example (not actual AES S-box)
            data_out <= sbox[addr_in] ^ data_in;
        end
    end
endmodule