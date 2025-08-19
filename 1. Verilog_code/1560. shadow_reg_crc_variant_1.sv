//SystemVerilog
module shadow_reg_crc_pipeline #(parameter DW=8) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output reg [DW+3:0] reg_out  // [DW+3:DW]为CRC
);

    // Pipeline registers
    reg [3:0] a_stage1, b_stage1;
    reg [3:0] g_stage2, p_stage2;
    reg [4:0] c_stage3;
    reg [3:0] crc_stage4;

    // Stage 1: Input and split data
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a_stage1 <= 0;
            b_stage1 <= 0;
        end else if (en) begin
            a_stage1 <= data_in[3:0];
            b_stage1 <= data_in[7:4];
        end
    end

    // Stage 2: Generate and propagate signals
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            g_stage2 <= 0;
            p_stage2 <= 0;
        end else if (en) begin
            g_stage2 <= a_stage1 & b_stage1;  // Generate signals
            p_stage2 <= a_stage1 ^ b_stage1;  // Propagate signals
        end
    end

    // Stage 3: Calculate carry signals
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_stage3 <= 0;
        end else if (en) begin
            c_stage3[0] <= 1'b0;  // Initial carry
            c_stage3[1] <= g_stage2[0] | (p_stage2[0] & c_stage3[0]);
            c_stage3[2] <= g_stage2[1] | (p_stage2[1] & g_stage2[0]) | (p_stage2[1] & p_stage2[0] & c_stage3[0]);
            c_stage3[3] <= g_stage2[2] | (p_stage2[2] & g_stage2[1]) | (p_stage2[2] & p_stage2[1] & g_stage2[0]) | (p_stage2[2] & p_stage2[1] & p_stage2[0] & c_stage3[0]);
            c_stage3[4] <= g_stage2[3] | (p_stage2[3] & g_stage2[2]) | (p_stage2[3] & p_stage2[2] & g_stage2[1]) | (p_stage2[3] & p_stage2[2] & p_stage2[1] & g_stage2[0]) | (p_stage2[3] & p_stage2[2] & p_stage2[1] & p_stage2[0] & c_stage3[0]);
        end
    end

    // Stage 4: Final CRC result
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_out <= 0;
            crc_stage4 <= 0;
        end else if (en) begin
            crc_stage4 <= p_stage2 ^ c_stage3[3:0];  // Final CRC result
            reg_out <= {crc_stage4, data_in};  // Output
        end
    end

endmodule