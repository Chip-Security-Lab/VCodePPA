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
    reg [RATIO_WIDTH-1:0] counter;
    reg hs_phase;
    wire [RATIO_WIDTH-1:0] next_counter;
    wire borrow;
    
    // 二进制补码减法实现
    wire [RATIO_WIDTH-1:0] one_complement = ~1'b1;
    wire [RATIO_WIDTH-1:0] two_complement = one_complement + 1'b1;
    wire [RATIO_WIDTH:0] temp_sum = counter + two_complement;
    assign {borrow, next_counter} = temp_sum;
    
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= div_ratio;
            hs_phase <= 0;
        end else begin
            if (borrow) begin
                counter <= div_ratio;
                hs_phase <= ~hs_phase;
            end else begin
                counter <= next_counter;
            end
        end
    end
    
    assign hs_clk = hs_phase;
    assign lp_clk = ~hs_phase;
endmodule