//SystemVerilog
module int_ctrl_pipe3 #(
    parameter WIDTH = 16
)(
    input clk, rst,
    input [WIDTH-1:0] req_in,
    output reg [4:0] grant_out
);
    reg [WIDTH-1:0] req_stage1, req_stage2;
    reg [4:0] encoder_result;
    reg [4:0] code_stage1, code_stage2;
    reg req_valid_stage2;
    
    // 优化后的编码器函数 - 平衡逻辑路径
    function [4:0] encoder;
        input [WIDTH-1:0] value;
        reg [4:0] result;
        reg found;
        integer i;
        begin
            result = 5'h1F; // 默认值
            found = 1'b0;
            
            // 高8位优先判断
            for (i = WIDTH-1; i >= WIDTH/2 && !found; i = i - 1) begin
                if (value[i]) begin
                    result = i[4:0];
                    found = 1'b1;
                end
            end
            
            // 如果高8位没有，再判断低8位
            if (!found) begin
                for (i = WIDTH/2-1; i >= 0; i = i - 1) begin
                    if (value[i]) result = i[4:0];
                end
            end
            
            encoder = result;
        end
    endfunction
    
    // 预先计算编码结果
    always @(*) begin
        encoder_result = encoder(req_in);
    end
    
    // 管道阶段1 - 复位逻辑
    always @(posedge clk) begin
        if (rst) begin
            req_stage1 <= {WIDTH{1'b0}};
            code_stage1 <= 5'h1F;
        end else begin
            req_stage1 <= req_in;
            code_stage1 <= encoder_result;
        end
    end
    
    // 管道阶段2 - 复位逻辑
    always @(posedge clk) begin
        if (rst) begin
            req_stage2 <= {WIDTH{1'b0}};
            code_stage2 <= 5'h1F;
            req_valid_stage2 <= 1'b0;
        end else begin
            req_stage2 <= req_stage1;
            code_stage2 <= code_stage1;
            req_valid_stage2 <= (req_stage1 != {WIDTH{1'b0}});
        end
    end
    
    // 管道阶段3 - 输出逻辑
    always @(posedge clk) begin
        if (rst) begin
            grant_out <= 5'h1F;
        end else begin
            grant_out <= req_valid_stage2 ? code_stage2 : 5'h1F;
        end
    end
endmodule