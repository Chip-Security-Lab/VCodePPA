module sine_lut(
    input clk,
    input rst_n,
    input [3:0] addr_step,
    output reg [7:0] sine_out
);
    reg [7:0] addr;
    reg [7:0] sine_table [0:15];
    
    initial begin
        sine_table[0] = 8'd128;
        sine_table[1] = 8'd176;
        sine_table[2] = 8'd218;
        sine_table[3] = 8'd245;
        sine_table[4] = 8'd255;
        sine_table[5] = 8'd245;
        sine_table[6] = 8'd218;
        sine_table[7] = 8'd176;
        sine_table[8] = 8'd128;
        sine_table[9] = 8'd79;
        sine_table[10] = 8'd37;
        sine_table[11] = 8'd10;
        sine_table[12] = 8'd0;
        sine_table[13] = 8'd10;
        sine_table[14] = 8'd37;
        sine_table[15] = 8'd79;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            addr <= 8'd0;
        else
            addr <= addr + addr_step;
    end
    
    always @(posedge clk)
        sine_out <= sine_table[addr[7:4]];
endmodule