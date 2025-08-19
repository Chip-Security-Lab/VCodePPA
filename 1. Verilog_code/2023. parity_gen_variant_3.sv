//SystemVerilog
// Top-level: Structured, pipelined parity generator

module parity_generator_top #(parameter TYPE = 0) (
    input         clk,
    input         rst_n,
    input  [7:0]  data_in,
    output        parity_out
);

    // Stage 1: Input data register (improves timing/throughput)
    reg [7:0] data_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_stage1 <= 8'd0;
        else
            data_stage1 <= data_in;
    end

    // Stage 2: Partial XOR reduction (pipeline for clarity and timing)
    wire [3:0] xor_stage2;
    parity_xor4 u_xor4_stage2_0 (
        .data_in  (data_stage1[3:0]),
        .xor_out  (xor_stage2[0])
    );
    parity_xor4 u_xor4_stage2_1 (
        .data_in  (data_stage1[7:4]),
        .xor_out  (xor_stage2[1])
    );

    // Stage 2 register
    reg [1:0] xor_stage2_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            xor_stage2_reg <= 2'b0;
        else begin
            xor_stage2_reg[0] <= xor_stage2[0];
            xor_stage2_reg[1] <= xor_stage2[1];
        end
    end

    // Stage 3: Final XOR and pipeline register
    wire xor_stage3;
    assign xor_stage3 = xor_stage2_reg[0] ^ xor_stage2_reg[1];

    reg raw_parity_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            raw_parity_reg <= 1'b0;
        else
            raw_parity_reg <= xor_stage3;
    end

    // Stage 4: Parity type adjustment (even/odd) and pipeline register
    wire parity_adjusted;
    assign parity_adjusted = (TYPE == 1'b0) ? raw_parity_reg : ~raw_parity_reg;

    reg parity_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            parity_out_reg <= 1'b0;
        else
            parity_out_reg <= parity_adjusted;
    end

    assign parity_out = parity_out_reg;

endmodule

// 4-bit XOR reduction module (pipeline helper)
module parity_xor4 (
    input  [3:0] data_in,
    output       xor_out
);
    assign xor_out = data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3];
endmodule