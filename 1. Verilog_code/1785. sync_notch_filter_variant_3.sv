//SystemVerilog
module sync_notch_filter #(
    parameter DW = 10
)(
    input clk, rst_n,
    input [DW-1:0] x_in,
    input [DW-1:0] notch_freq,
    input [DW-1:0] q_factor,
    output [DW-1:0] y_out
);
    // Stage 1 registers
    reg [DW-1:0] x1_reg, x2_reg, y1_reg, y2_reg;
    reg [DW-1:0] notch_freq_reg, q_factor_reg;
    reg [DW-1:0] x_in_reg;
    
    // Stage 2 registers
    reg [DW-1:0] b0_reg, b1_reg, b2_reg, a1_reg, a2_reg;
    reg [DW-1:0] x1_stage2, x2_stage2, y1_stage2, y2_stage2;
    
    // Stage 3 registers
    reg [2*DW-1:0] term1_reg, term2_reg, term3_reg, term4_reg, term5_reg;
    
    // Stage 4 registers
    reg [2*DW-1:0] pos_sum_reg, neg_sum_reg;
    
    // Stage 5 registers
    reg [2*DW-1:0] filter_result_reg;
    reg [DW-1:0] y_out_reg;

    // Stage 1: Input and coefficient calculation
    wire [DW-1:0] b0, b1, b2, a1, a2;
    assign b0 = q_factor_reg;
    assign b1 = -{DW{1'b1}};
    assign b2 = q_factor_reg;
    assign a1 = -{DW{1'b1}};
    assign a2 = (q_factor_reg << 1) - (notch_freq_reg >> 2);

    // Stage 3: Term calculations
    wire [2*DW-1:0] term1, term2, term3, term4, term5;
    assign term1 = b0_reg * x_in_reg;
    assign term2 = b1_reg * x1_stage2;
    assign term3 = b2_reg * x2_stage2;
    assign term4 = a1_reg * y1_stage2;
    assign term5 = a2_reg * y2_stage2;

    // Stage 4: Sum calculations
    wire [2*DW-1:0] pos_sum, neg_sum;
    assign pos_sum = term1_reg + term3_reg;
    assign neg_sum = term4_reg + term5_reg - term2_reg;

    // Stage 5: Final result
    wire [2*DW-1:0] filter_result;
    assign filter_result = pos_sum_reg - neg_sum_reg;
    assign y_out = y_out_reg;

    // Pipeline control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Stage 1 reset
            x1_reg <= {DW{1'b0}};
            x2_reg <= {DW{1'b0}};
            y1_reg <= {DW{1'b0}};
            y2_reg <= {DW{1'b0}};
            notch_freq_reg <= {DW{1'b0}};
            q_factor_reg <= {DW{1'b0}};
            x_in_reg <= {DW{1'b0}};
            
            // Stage 2 reset
            b0_reg <= {DW{1'b0}};
            b1_reg <= {DW{1'b0}};
            b2_reg <= {DW{1'b0}};
            a1_reg <= {DW{1'b0}};
            a2_reg <= {DW{1'b0}};
            x1_stage2 <= {DW{1'b0}};
            x2_stage2 <= {DW{1'b0}};
            y1_stage2 <= {DW{1'b0}};
            y2_stage2 <= {DW{1'b0}};
            
            // Stage 3 reset
            term1_reg <= {(2*DW){1'b0}};
            term2_reg <= {(2*DW){1'b0}};
            term3_reg <= {(2*DW){1'b0}};
            term4_reg <= {(2*DW){1'b0}};
            term5_reg <= {(2*DW){1'b0}};
            
            // Stage 4 reset
            pos_sum_reg <= {(2*DW){1'b0}};
            neg_sum_reg <= {(2*DW){1'b0}};
            
            // Stage 5 reset
            filter_result_reg <= {(2*DW){1'b0}};
            y_out_reg <= {DW{1'b0}};
        end else begin
            // Stage 1 update
            x2_reg <= x1_reg;
            x1_reg <= x_in;
            y2_reg <= y1_reg;
            y1_reg <= filter_result_reg[2*DW-1:DW];
            notch_freq_reg <= notch_freq;
            q_factor_reg <= q_factor;
            x_in_reg <= x_in;
            
            // Stage 2 update
            b0_reg <= b0;
            b1_reg <= b1;
            b2_reg <= b2;
            a1_reg <= a1;
            a2_reg <= a2;
            x1_stage2 <= x1_reg;
            x2_stage2 <= x2_reg;
            y1_stage2 <= y1_reg;
            y2_stage2 <= y2_reg;
            
            // Stage 3 update
            term1_reg <= term1;
            term2_reg <= term2;
            term3_reg <= term3;
            term4_reg <= term4;
            term5_reg <= term5;
            
            // Stage 4 update
            pos_sum_reg <= pos_sum;
            neg_sum_reg <= neg_sum;
            
            // Stage 5 update
            filter_result_reg <= filter_result;
            y_out_reg <= filter_result[2*DW-1:DW];
        end
    end
endmodule