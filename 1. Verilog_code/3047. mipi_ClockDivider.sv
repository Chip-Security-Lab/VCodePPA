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
    reg [RATIO_WIDTH-1:0] counter;
    reg hs_phase;
    
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            hs_phase <= 0;
        end else begin
            if (counter == div_ratio) begin
                counter <= 0;
                hs_phase <= ~hs_phase;
            end else begin
                counter <= counter + 1;
            end
        end
    end
    
    assign hs_clk = hs_phase;
    assign lp_clk = ~hs_phase;  // 互补输出
endmodule
