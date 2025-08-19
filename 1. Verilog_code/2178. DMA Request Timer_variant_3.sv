//SystemVerilog
module dma_timer #(parameter WIDTH = 24)(
    input clk, rst,
    input [WIDTH-1:0] period, threshold,
    output reg [WIDTH-1:0] count,
    output reg dma_req, period_match
);
    // Fan-out buffering registers for high fan-out 'count' signal
    reg [WIDTH-1:0] count_buf1, count_buf2;
    
    // 使用补码加法实现减法：(period - 1) 等价于 (period + (~1 + 1))，即 period + ~1
    wire [WIDTH-1:0] period_minus_one = period + {WIDTH{1'b1}}; // period + ~1
    
    // 使用补码加法实现减法：(threshold - 1) 等价于 (threshold + (~1 + 1))，即 threshold + ~1
    wire [WIDTH-1:0] threshold_minus_one = threshold + {WIDTH{1'b1}}; // threshold + ~1
    
    // 使用补码加法后的比较逻辑
    wire period_compare = (count_buf1 == period_minus_one);
    wire threshold_compare = (count_buf2 == threshold_minus_one);
    
    always @(posedge clk) begin
        if (rst) begin 
            count <= {WIDTH{1'b0}}; 
            count_buf1 <= {WIDTH{1'b0}};
            count_buf2 <= {WIDTH{1'b0}};
            period_match <= 1'b0;
            dma_req <= 1'b0;
        end
        else begin
            // Buffer the count signal to reduce fan-out
            count_buf1 <= count;
            count_buf2 <= count;
            
            if (period_compare) begin
                count <= {WIDTH{1'b0}}; 
                period_match <= 1'b1;
            end 
            else begin 
                count <= count + 1'b1; 
                period_match <= 1'b0; 
            end
            
            dma_req <= threshold_compare;
        end
    end
endmodule