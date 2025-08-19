module gcm_auth #(parameter WIDTH = 32) (
    input wire clk, reset_l,
    input wire data_valid, last_block,
    input wire [WIDTH-1:0] data_in, h_key,
    output reg [WIDTH-1:0] auth_tag,
    output reg tag_valid
);
    reg [WIDTH-1:0] accumulated;
    
    // GF(2^128) multiplication (simplified for this example)
    function [WIDTH-1:0] gf_mult(input [WIDTH-1:0] a, b);
        reg [WIDTH-1:0] res;
        reg carry;
        integer i, j;
        begin
            res = 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (a[i]) res = res ^ (b << i);
            end
            // Reduction step (simplified)
            for (j = WIDTH*2-1; j >= WIDTH; j = j - 1) begin
                if (res[j]) res = res ^ (32'h87000000 << (j - WIDTH));
            end
            gf_mult = res;
        end
    endfunction
    
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            accumulated <= 0;
            tag_valid <= 0;
        end else if (data_valid) begin
            accumulated <= gf_mult(accumulated ^ data_in, h_key);
            tag_valid <= last_block;
            if (last_block) auth_tag <= accumulated ^ data_in;
        end
    end
endmodule