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
    reg [DW-1:0] x_in_stage1, notch_freq_stage1, q_factor_stage1;
    reg [DW-1:0] b0_stage1, b1_stage1, b2_stage1, a1_stage1;
    reg [DW-1:0] shift_result_stage1;
    
    // Stage 2 registers
    reg [DW-1:0] x_in_stage2, x1_stage2;
    reg [DW-1:0] b0_stage2, b1_stage2, b2_stage2, a1_stage2, a2_stage2;
    reg [2*DW-1:0] acc_stage2;
    
    // Stage 3 registers
    reg [DW-1:0] x1_stage3, x2_stage3, y1_stage3, y2_stage3;
    reg [2*DW-1:0] acc_stage3;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Coefficient calculation
    wire [DW-1:0] b0 = q_factor;
    wire [DW-1:0] b1 = -{DW{1'b1}};
    wire [DW-1:0] b2 = q_factor;
    wire [DW-1:0] a1 = -{DW{1'b1}};
    
    // Barrel shifter implementation
    wire [DW-1:0] stage1_out = notch_freq[DW-1:1];
    wire [DW-1:0] shift_result = {2'b00, stage1_out[DW-1:2]};
    wire [DW-1:0] a2 = (q_factor << 1) - shift_result;
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 0;
            x_in_stage1 <= 0;
            notch_freq_stage1 <= 0;
            q_factor_stage1 <= 0;
            b0_stage1 <= 0;
            b1_stage1 <= 0;
            b2_stage1 <= 0;
            a1_stage1 <= 0;
            shift_result_stage1 <= 0;
        end else begin
            valid_stage1 <= 1;
            x_in_stage1 <= x_in;
            notch_freq_stage1 <= notch_freq;
            q_factor_stage1 <= q_factor;
            b0_stage1 <= b0;
            b1_stage1 <= b1;
            b2_stage1 <= b2;
            a1_stage1 <= a1;
            shift_result_stage1 <= shift_result;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 0;
            x_in_stage2 <= 0;
            x1_stage2 <= 0;
            b0_stage2 <= 0;
            b1_stage2 <= 0;
            b2_stage2 <= 0;
            a1_stage2 <= 0;
            a2_stage2 <= 0;
            acc_stage2 <= 0;
        end else if (valid_stage1) begin
            valid_stage2 <= 1;
            x_in_stage2 <= x_in_stage1;
            x1_stage2 <= x1_stage3;
            b0_stage2 <= b0_stage1;
            b1_stage2 <= b1_stage1;
            b2_stage2 <= b2_stage1;
            a1_stage2 <= a1_stage1;
            a2_stage2 <= a2;
            acc_stage2 <= (b0_stage1*x_in_stage1 + b1_stage1*x1_stage3 + b2_stage1*x2_stage3 - 
                          a1_stage1*y1_stage3 - a2*y2_stage3);
        end
    end
    
    // Pipeline stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 0;
            x1_stage3 <= 0;
            x2_stage3 <= 0;
            y1_stage3 <= 0;
            y2_stage3 <= 0;
            acc_stage3 <= 0;
            y_out <= 0;
        end else if (valid_stage2) begin
            valid_stage3 <= 1;
            x1_stage3 <= x_in_stage2;
            x2_stage3 <= x1_stage2;
            y1_stage3 <= acc_stage2[2*DW-1:DW];
            y2_stage3 <= y1_stage3;
            acc_stage3 <= acc_stage2;
            y_out <= acc_stage2[2*DW-1:DW];
        end
    end
endmodule