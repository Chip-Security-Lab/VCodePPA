//SystemVerilog
module PipeMux #(parameter DW=8, STAGES=4) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire [3:0]            sel,
    input  wire [(16*DW)-1:0]    din,
    output wire [DW-1:0]         dout
);

    // Stage 0: Input register for all inputs
    reg [DW-1:0] din_reg_stage0 [0:15];
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i=0; i<16; i=i+1) begin
                din_reg_stage0[i] <= {DW{1'b0}};
            end
        end else begin
            for (i=0; i<16; i=i+1) begin
                din_reg_stage0[i] <= din[i*DW +: DW];
            end
        end
    end

    // Stage 1: mux level 0 (mux 2:1, 8 groups)
    reg [DW-1:0] mux_l0_stage1 [0:7];
    always @(posedge clk) begin
        if (rst) begin
            for (i=0; i<8; i=i+1) begin
                mux_l0_stage1[i] <= {DW{1'b0}};
            end
        end else begin
            mux_l0_stage1[0] <= sel[0] ? din_reg_stage0[1]  : din_reg_stage0[0];
            mux_l0_stage1[1] <= sel[0] ? din_reg_stage0[3]  : din_reg_stage0[2];
            mux_l0_stage1[2] <= sel[0] ? din_reg_stage0[5]  : din_reg_stage0[4];
            mux_l0_stage1[3] <= sel[0] ? din_reg_stage0[7]  : din_reg_stage0[6];
            mux_l0_stage1[4] <= sel[0] ? din_reg_stage0[9]  : din_reg_stage0[8];
            mux_l0_stage1[5] <= sel[0] ? din_reg_stage0[11] : din_reg_stage0[10];
            mux_l0_stage1[6] <= sel[0] ? din_reg_stage0[13] : din_reg_stage0[12];
            mux_l0_stage1[7] <= sel[0] ? din_reg_stage0[15] : din_reg_stage0[14];
        end
    end

    // Stage 2: mux level 1 (mux 2:1, 4 groups)
    reg [DW-1:0] mux_l1_stage2 [0:3];
    always @(posedge clk) begin
        if (rst) begin
            for (i=0; i<4; i=i+1) begin
                mux_l1_stage2[i] <= {DW{1'b0}};
            end
        end else begin
            mux_l1_stage2[0] <= sel[1] ? mux_l0_stage1[1] : mux_l0_stage1[0];
            mux_l1_stage2[1] <= sel[1] ? mux_l0_stage1[3] : mux_l0_stage1[2];
            mux_l1_stage2[2] <= sel[1] ? mux_l0_stage1[5] : mux_l0_stage1[4];
            mux_l1_stage2[3] <= sel[1] ? mux_l0_stage1[7] : mux_l0_stage1[6];
        end
    end

    // Stage 3: mux level 2 (mux 2:1, 2 groups)
    reg [DW-1:0] mux_l2_stage3 [0:1];
    always @(posedge clk) begin
        if (rst) begin
            mux_l2_stage3[0] <= {DW{1'b0}};
            mux_l2_stage3[1] <= {DW{1'b0}};
        end else begin
            mux_l2_stage3[0] <= sel[2] ? mux_l1_stage2[1] : mux_l1_stage2[0];
            mux_l2_stage3[1] <= sel[2] ? mux_l1_stage2[3] : mux_l1_stage2[2];
        end
    end

    // Stage 4: mux level 3 (final 2:1 mux)
    reg [DW-1:0] dout_stage4;
    always @(posedge clk) begin
        if (rst) begin
            dout_stage4 <= {DW{1'b0}};
        end else begin
            dout_stage4 <= sel[3] ? mux_l2_stage3[1] : mux_l2_stage3[0];
        end
    end

    assign dout = dout_stage4;

endmodule