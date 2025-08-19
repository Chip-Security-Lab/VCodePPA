//SystemVerilog
module int_ctrl_pipe3 #(
    parameter WIDTH = 16
)(
    input clk, rst,
    input [WIDTH-1:0] req_in,
    output reg [4:0] grant_out
);
    // 流水线寄存器
    reg [WIDTH-1:0] req_stage1, req_stage2;
    reg [4:0] code_stage1, code_stage2;
    reg req_valid_stage2;
    
    // 添加编码器函数
    function [4:0] encoder;
        input [WIDTH-1:0] value;
        integer i;
        begin
            encoder = 5'h1F; // 默认值
            for (i = WIDTH-1; i >= 0; i = i - 1) begin
                if (value[i]) encoder = i[4:0];
            end
        end
    endfunction
    
    // 流水线第一阶段 - 请求捕获
    always @(posedge clk) begin
        if (rst) begin
            req_stage1 <= {WIDTH{1'b0}};
        end else begin
            req_stage1 <= req_in;
        end
    end
    
    // 流水线第一阶段 - 编码
    always @(posedge clk) begin
        if (rst) begin
            code_stage1 <= 5'h1F;
        end else begin
            code_stage1 <= encoder(req_in);
        end
    end
    
    // 流水线第二阶段 - 请求传递
    always @(posedge clk) begin
        if (rst) begin
            req_stage2 <= {WIDTH{1'b0}};
        end else begin
            req_stage2 <= req_stage1;
        end
    end
    
    // 流水线第二阶段 - 编码传递
    always @(posedge clk) begin
        if (rst) begin
            code_stage2 <= 5'h1F;
        end else begin
            code_stage2 <= code_stage1;
        end
    end
    
    // 流水线第二阶段 - 请求有效性检查
    always @(posedge clk) begin
        if (rst) begin
            req_valid_stage2 <= 1'b0;
        end else begin
            req_valid_stage2 <= (req_stage1 != {WIDTH{1'b0}});
        end
    end
    
    // 流水线第三阶段 - 输出生成
    always @(posedge clk) begin
        if (rst) begin
            grant_out <= 5'h1F;
        end else begin
            grant_out <= req_valid_stage2 ? code_stage2 : 5'h1F;
        end
    end
endmodule