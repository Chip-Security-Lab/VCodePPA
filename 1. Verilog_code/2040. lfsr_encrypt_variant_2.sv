//SystemVerilog
module lfsr_encrypt #(parameter SEED=8'hFF, POLY=8'h1D) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    output reg  [7:0]  encrypted
);
    reg  [7:0] lfsr_next;
    reg  [7:0] lfsr_reg;

    // Forward retiming: Move lfsr register after LFSR combinational logic
    always @(*) begin
        lfsr_next = {lfsr_reg[6:0], 1'b0} ^ (POLY & {8{lfsr_reg[7]}});
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg   <= SEED;
            encrypted  <= 8'd0;
        end else begin
            lfsr_reg   <= lfsr_next;
            encrypted  <= data_in ^ lfsr_next;
        end
    end
endmodule