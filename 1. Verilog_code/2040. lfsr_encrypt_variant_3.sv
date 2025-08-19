//SystemVerilog
module lfsr_encrypt #(parameter SEED=8'hFF, POLY=8'h1D) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    output reg  [7:0]  encrypted
);
    reg [7:0] lfsr_reg;
    reg [7:0] lfsr_buf1;
    reg [7:0] lfsr_buf2;

    // Combined LFSR and Buffer Stages, Encryption Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg   <= SEED;
            lfsr_buf1  <= SEED;
            lfsr_buf2  <= SEED;
            encrypted  <= 8'b0;
        end else begin
            lfsr_reg   <= {lfsr_reg[6:0], 1'b0} ^ (POLY & {8{lfsr_reg[7]}});
            lfsr_buf1  <= lfsr_reg;
            lfsr_buf2  <= lfsr_buf1;
            encrypted  <= data_in ^ lfsr_buf2;
        end
    end
endmodule