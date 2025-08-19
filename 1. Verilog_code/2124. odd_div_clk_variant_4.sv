//SystemVerilog
module odd_div_clk #(
    parameter N = 5
)(
    input clk_in,
    input reset,
    output clk_div
);
    reg [2:0] posedge_counter;
    reg [2:0] negedge_counter;
    reg clk_p, clk_n;
    
    // 判断逻辑优化，将比较逻辑分离出来
    wire posedge_threshold_met = (posedge_counter >= ((N-1)/2));
    wire negedge_threshold_met = (negedge_counter >= ((N-1)/2));
    
    // Posedge counter - 优化后先计算下一状态，再寄存
    always @(posedge clk_in) begin
        if (reset) begin
            posedge_counter <= 3'd0;
            clk_p <= 1'b0;
        end else begin
            if (posedge_threshold_met) begin
                posedge_counter <= 3'd0;
                clk_p <= ~clk_p;
            end else begin
                posedge_counter <= posedge_counter + 1'b1;
            end
        end
    end
    
    // Negedge counter - 优化后先计算下一状态，再寄存
    always @(negedge clk_in) begin
        if (reset) begin
            negedge_counter <= 3'd0;
            clk_n <= 1'b0;
        end else begin
            if (negedge_threshold_met) begin
                negedge_counter <= 3'd0;
                clk_n <= ~clk_n;
            end else begin
                negedge_counter <= negedge_counter + 1'b1;
            end
        end
    end
    
    // 时钟输出逻辑
    assign clk_div = clk_p | clk_n;
endmodule