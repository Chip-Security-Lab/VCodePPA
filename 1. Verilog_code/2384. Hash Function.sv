module hash_function #(parameter DATA_WIDTH = 32, HASH_WIDTH = 16) (
    input wire clk, rst_n, enable,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire last_block,
    output reg [HASH_WIDTH-1:0] hash_out,
    output reg hash_valid
);
    reg [HASH_WIDTH-1:0] hash_state;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            hash_state <= {HASH_WIDTH{1'b1}}; // Initial value
            hash_valid <= 1'b0;
        end else if (enable) begin
            hash_state <= hash_state ^ {data_in[15:0] ^ data_in[31:16]};
            hash_valid <= last_block;
            if (last_block) hash_out <= hash_state;
        end
    end
endmodule