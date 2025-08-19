//SystemVerilog
module rng_shiftxor_6(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  rnd
);
    reg [7:0] lfsr_state;
    wire xor_stage1;
    wire xor_stage2;
    wire xor_combined;
    wire feedback;

    // 分层次进行异或，平衡路径
    assign xor_stage1 = lfsr_state[7] ^ lfsr_state[6];
    assign xor_stage2 = lfsr_state[5] ^ lfsr_state[4];
    assign xor_combined = xor_stage1 ^ xor_stage2;
    assign feedback = xor_combined;

    always @(posedge clk) begin
        case ({rst, en})
            2'b10: lfsr_state <= 8'hF0;
            2'b01: lfsr_state <= {lfsr_state[6:0], feedback};
            default: lfsr_state <= lfsr_state;
        endcase
    end

    always @(*) begin
        rnd = lfsr_state;
    end
endmodule