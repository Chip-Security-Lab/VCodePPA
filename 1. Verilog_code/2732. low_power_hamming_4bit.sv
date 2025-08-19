module low_power_hamming_4bit(
    input clk, sleep_mode,
    input [3:0] data,
    output reg [6:0] encoded
);
    wire power_save_clk;
    assign power_save_clk = clk & ~sleep_mode;
    
    always @(posedge power_save_clk) begin
        if (sleep_mode) encoded <= 7'b0;
        else begin
            encoded[0] <= data[0] ^ data[1] ^ data[3];
            encoded[1] <= data[0] ^ data[2] ^ data[3];
            encoded[2] <= data[0];
            encoded[3] <= data[1] ^ data[2] ^ data[3];
            encoded[4] <= data[1];
            encoded[5] <= data[2];
            encoded[6] <= data[3];
        end
    end
endmodule