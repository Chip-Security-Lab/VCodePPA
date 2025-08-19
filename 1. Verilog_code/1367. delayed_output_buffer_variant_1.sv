//SystemVerilog
module delayed_output_buffer (
    input wire clk,
    input wire [7:0] data_in,
    input wire load,
    output reg [7:0] data_out,
    output reg data_valid
);
    // 优化后的流水线结构 - 直接从输入向输出推进
    reg [7:0] buffer_stage2;
    reg [7:0] buffer_stage3;
    
    reg valid_stage2;
    reg valid_stage3;
    
    // 合并第一级和最终级 - 直接从输入获取数据
    always @(posedge clk) begin
        if (load) begin
            buffer_stage2 <= data_in;  // 直接从输入获取
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
        
        // 同时更新第三级
        buffer_stage3 <= buffer_stage2;
        valid_stage3 <= valid_stage2;
        
        // 最终输出
        data_out <= buffer_stage3;
        data_valid <= valid_stage3;
    end
endmodule