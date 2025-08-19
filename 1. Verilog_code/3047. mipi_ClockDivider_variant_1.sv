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

    // Counter registers
    reg [RATIO_WIDTH-1:0] counter_reg;
    reg counter_wrap_reg;
    
    // Phase registers
    reg hs_phase_reg;
    reg hs_clk_reg;
    reg lp_clk_reg;
    
    // Counter logic
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= (counter_reg == div_ratio) ? 1 : (counter_reg + 1);
        end
    end
    
    // Counter wrap detection
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_wrap_reg <= 0;
        end else begin
            counter_wrap_reg <= (counter_reg == div_ratio);
        end
    end
    
    // Phase generation
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            hs_phase_reg <= 0;
        end else if (counter_wrap_reg) begin
            hs_phase_reg <= ~hs_phase_reg;
        end
    end
    
    // Output generation
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            hs_clk_reg <= 0;
            lp_clk_reg <= 1;
        end else begin
            hs_clk_reg <= hs_phase_reg;
            lp_clk_reg <= ~hs_phase_reg;
        end
    end
    
    assign hs_clk = hs_clk_reg;
    assign lp_clk = lp_clk_reg;
    
endmodule