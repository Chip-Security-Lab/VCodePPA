//SystemVerilog
module basic_left_shift #(parameter DATA_WIDTH = 8) (
    input clk_i,
    input rst_i,
    input si,            // Serial input
    output so            // Serial output
);
    reg [DATA_WIDTH-1:0] sr;
    
    // 重构以降低功耗并改善时序
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            sr <= {DATA_WIDTH{1'b0}};
        else
            sr <= {sr[DATA_WIDTH-2:0], si};
    end
    
    // 直接从寄存器中获取输出，减少输出延迟
    assign so = sr[DATA_WIDTH-1];
endmodule