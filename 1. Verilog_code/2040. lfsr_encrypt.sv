module lfsr_encrypt #(parameter SEED=8'hFF, POLY=8'h1D) (
    input clk, rst_n,
    input [7:0] data_in,
    output reg [7:0] encrypted
);
    reg [7:0] lfsr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) lfsr <= SEED;
        else begin
            lfsr <= {lfsr[6:0], 1'b0} ^ (POLY & {8{lfsr[7]}});
            encrypted <= data_in ^ lfsr;
        end
    end
endmodule