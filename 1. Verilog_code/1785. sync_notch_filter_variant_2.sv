//SystemVerilog
module sync_notch_filter #(
    parameter DW = 10
)(
    input clk, rst_n,
    input [DW-1:0] x_in,
    input [DW-1:0] notch_freq,
    input [DW-1:0] q_factor,
    output reg [DW-1:0] y_out
);

    // Stage 1 registers
    reg [DW-1:0] x_in_stage1;
    reg [DW-1:0] notch_freq_stage1;
    reg [DW-1:0] q_factor_stage1;
    reg [DW-1:0] x1_stage1, x2_stage1;
    reg [DW-1:0] y1_stage1, y2_stage1;
    
    // Stage 2 registers
    reg [DW-1:0] x1_stage2, x2_stage2;
    reg [DW-1:0] y1_stage2, y2_stage2;
    reg [DW-1:0] b0_stage2, b1_stage2, b2_stage2;
    reg [DW-1:0] a1_stage2, a2_stage2;
    
    // Stage 3 registers
    reg [2*DW-1:0] acc_stage3;
    reg [DW-1:0] y_out_stage3;
    
    // Stage 1: Input sampling and coefficient calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_in_stage1 <= 0;
            notch_freq_stage1 <= 0;
            q_factor_stage1 <= 0;
            x1_stage1 <= 0;
            x2_stage1 <= 0;
            y1_stage1 <= 0;
            y2_stage1 <= 0;
        end else begin
            x_in_stage1 <= x_in;
            notch_freq_stage1 <= notch_freq;
            q_factor_stage1 <= q_factor;
            x1_stage1 <= x_in;
            x2_stage1 <= x1_stage1;
            y1_stage1 <= y_out_stage3;
            y2_stage1 <= y1_stage1;
        end
    end
    
    // Stage 2: Coefficient calculation and data preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x1_stage2 <= 0;
            x2_stage2 <= 0;
            y1_stage2 <= 0;
            y2_stage2 <= 0;
            b0_stage2 <= 0;
            b1_stage2 <= 0;
            b2_stage2 <= 0;
            a1_stage2 <= 0;
            a2_stage2 <= 0;
        end else begin
            x1_stage2 <= x1_stage1;
            x2_stage2 <= x2_stage1;
            y1_stage2 <= y1_stage1;
            y2_stage2 <= y2_stage1;
            b0_stage2 <= q_factor_stage1;
            b1_stage2 <= -{DW{1'b1}};
            b2_stage2 <= q_factor_stage1;
            a1_stage2 <= -{DW{1'b1}};
            a2_stage2 <= (q_factor_stage1 * 2) - (notch_freq_stage1 >> 2);
        end
    end
    
    // Stage 3: Filter calculation and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_stage3 <= 0;
            y_out_stage3 <= 0;
            y_out <= 0;
        end else begin
            acc_stage3 <= (b0_stage2*x1_stage2 + b1_stage2*x2_stage2 + b2_stage2*x2_stage2 - 
                          a1_stage2*y1_stage2 - a2_stage2*y2_stage2);
            y_out_stage3 <= acc_stage3[2*DW-1:DW];
            y_out <= y_out_stage3;
        end
    end
endmodule