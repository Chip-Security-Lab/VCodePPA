//SystemVerilog
module MIPI_ClockDivider #(
    parameter RATIO_WIDTH = 8,
    parameter INIT_RATIO = 4
)(
    input wire ref_clk,
    input wire rst_n,
    input wire [RATIO_WIDTH-1:0] div_ratio,
    output wire hs_clk,
    output wire lp_clk
);
    reg [RATIO_WIDTH-1:0] counter_stage1;
    reg [RATIO_WIDTH-1:0] counter_stage2;
    reg hs_phase_stage1;
    reg hs_phase_stage2;
    wire counter_match_stage1;
    wire counter_match_stage2;
    
    assign counter_match_stage1 = (counter_stage1 == div_ratio);
    assign counter_match_stage2 = (counter_stage2 == div_ratio);
    
    // Stage 1: Counter update
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= {RATIO_WIDTH{1'b0}};
            hs_phase_stage1 <= 1'b0;
        end else begin
            counter_stage1 <= counter_match_stage1 ? {RATIO_WIDTH{1'b0}} : (counter_stage1 + 1'b1);
            hs_phase_stage1 <= counter_match_stage1 ? ~hs_phase_stage1 : hs_phase_stage1;
        end
    end
    
    // Stage 2: Phase update
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= {RATIO_WIDTH{1'b0}};
            hs_phase_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            hs_phase_stage2 <= hs_phase_stage1;
        end
    end
    
    assign hs_clk = hs_phase_stage2;
    assign lp_clk = ~hs_phase_stage2;
endmodule