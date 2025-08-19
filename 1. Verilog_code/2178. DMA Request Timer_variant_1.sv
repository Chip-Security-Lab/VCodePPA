//SystemVerilog
module dma_timer #(parameter WIDTH = 24)(
    input clk, rst,
    input [WIDTH-1:0] period, threshold,
    output reg [WIDTH-1:0] count,
    output reg dma_req, period_match
);
    // 预计算下一个count值
    wire [WIDTH-1:0] next_count = (count == period - 1'b1) ? {WIDTH{1'b0}} : count + 1'b1;
    
    // 提前计算比较结果
    wire period_match_comb = (count == period - 1'b1);
    wire threshold_match = (count == threshold - 1'b1);
    
    always @(posedge clk) begin
        if (rst) begin 
            count <= {WIDTH{1'b0}}; 
            period_match <= 1'b0;
        end
        else begin
            count <= next_count;
            period_match <= period_match_comb;
        end
    end
    
    always @(posedge clk) begin
        if (rst) 
            dma_req <= 1'b0;
        else 
            dma_req <= threshold_match;
    end
endmodule