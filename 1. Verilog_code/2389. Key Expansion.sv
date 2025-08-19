module key_expansion #(parameter KEY_WIDTH = 32, EXPANDED_WIDTH = 128) (
    input wire clk, rst_n,
    input wire key_load,
    input wire [KEY_WIDTH-1:0] key_in,
    output reg [EXPANDED_WIDTH-1:0] expanded_key,
    output reg key_ready
);
    reg [2:0] stage;
    reg [KEY_WIDTH-1:0] key_reg;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            stage <= 0;
            key_ready <= 0;
            expanded_key <= 0;
        end else if (key_load) begin
            key_reg <= key_in;
            stage <= 1;
            key_ready <= 0;
        end else if (stage > 0 && stage < 5) begin
            // Simple key expansion (in real implementation would be more complex)
            expanded_key[(stage-1)*KEY_WIDTH +: KEY_WIDTH] <= 
                key_reg ^ {key_reg[KEY_WIDTH-9:0], key_reg[KEY_WIDTH-1:KEY_WIDTH-8]} ^ {8'h01 << (stage-1), 24'h0};
            stage <= stage + 1;
            if (stage == 4) key_ready <= 1;
        end
    end
endmodule