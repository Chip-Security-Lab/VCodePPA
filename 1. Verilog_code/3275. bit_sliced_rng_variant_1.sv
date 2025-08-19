//SystemVerilog
module bit_sliced_rng (
    input wire clk_i,
    input wire rst_n_i,
    output wire [31:0] rnd_o
);
    reg [7:0] slice_reg0_stage1;
    reg [7:0] slice_reg1_stage1;
    reg [7:0] slice_reg2_stage1;
    reg [7:0] slice_reg3_stage1;

    // 合并反馈逻辑和寄存器更新为单级流水线
    wire feedback0_combined;
    wire feedback1_combined;
    wire feedback2_combined;
    wire feedback3_combined;

    assign feedback0_combined = slice_reg0_stage1[7] ^ slice_reg0_stage1[5] ^ slice_reg0_stage1[4] ^ slice_reg0_stage1[3];
    assign feedback1_combined = slice_reg1_stage1[7] ^ slice_reg1_stage1[6] ^ slice_reg1_stage1[1] ^ slice_reg1_stage1[0];
    assign feedback2_combined = slice_reg2_stage1[7] ^ slice_reg2_stage1[6] ^ slice_reg2_stage1[5] ^ slice_reg2_stage1[0];
    assign feedback3_combined = slice_reg3_stage1[7] ^ slice_reg3_stage1[3] ^ slice_reg3_stage1[2] ^ slice_reg3_stage1[1];

    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            slice_reg0_stage1 <= 8'h1;
            slice_reg1_stage1 <= 8'h2;
            slice_reg2_stage1 <= 8'h4;
            slice_reg3_stage1 <= 8'h8;
        end else begin
            slice_reg0_stage1 <= {slice_reg0_stage1[6:3], (slice_reg0_stage1[3]^slice_reg0_stage1[4]) ^ (slice_reg0_stage1[5]^slice_reg0_stage1[7]), slice_reg0_stage1[2:0], feedback0_combined};
            slice_reg1_stage1 <= {slice_reg1_stage1[6:1], (slice_reg1_stage1[1]^slice_reg1_stage1[0]) ^ (slice_reg1_stage1[6]^slice_reg1_stage1[7]), feedback1_combined};
            slice_reg2_stage1 <= {slice_reg2_stage1[6:1], (slice_reg2_stage1[0]^slice_reg2_stage1[5]) ^ (slice_reg2_stage1[6]^slice_reg2_stage1[7]), feedback2_combined};
            slice_reg3_stage1 <= {slice_reg3_stage1[6:2], (slice_reg3_stage1[1]^slice_reg3_stage1[2]) ^ (slice_reg3_stage1[3]^slice_reg3_stage1[7]), slice_reg3_stage1[1:0], feedback3_combined};
        end
    end

    assign rnd_o = {slice_reg3_stage1, slice_reg2_stage1, slice_reg1_stage1, slice_reg0_stage1};
endmodule