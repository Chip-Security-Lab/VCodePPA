//SystemVerilog
module int_ctrl_pipe5 #(
    parameter WIDTH = 16
)(
    input clk, rst,
    input [WIDTH-1:0] req_in,
    output reg [4:0] grant_out
);
    // 将输入端的寄存器向前移动，直接处理输入信号
    reg [WIDTH-1:0] req_pipe1, req_pipe2, req_pipe3, req_pipe4;
    wire [4:0] code_high, code_low;  // 编码器逻辑计算结果
    reg [4:0] code_high_reg, code_low_reg;
    reg [4:0] code_stage1, code_stage2, code_stage3;
    reg has_req_pipe1, has_req_pipe2, has_req_pipe3, has_req_pipe4;
    
    // 常量缓冲
    reg [4:0] h1F_const;
    
    // 优化编码器函数 - 高位部分
    function [4:0] encoder_high_fn;
        input [WIDTH-1:0] value;
        integer i;
        reg [4:0] result;
        begin
            result = 5'h1F; // 默认值
            for (i = WIDTH-1; i >= WIDTH/2; i = i - 1) begin
                if (value[i]) result = i[4:0];
            end
            encoder_high_fn = result;
        end
    endfunction
    
    // 优化编码器函数 - 低位部分
    function [4:0] encoder_low_fn;
        input [WIDTH-1:0] value;
        input [4:0] high_result;
        integer i;
        reg [4:0] result;
        begin
            result = high_result; // 默认使用高位结果
            if (high_result == 5'h1F) begin // 只有高位没有请求时才检查低位
                for (i = (WIDTH/2)-1; i >= 0; i = i - 1) begin
                    if (value[i]) result = i[4:0];
                end
            end
            encoder_low_fn = result;
        end
    endfunction
    
    // 将组合逻辑提前到寄存器之前
    assign code_high = encoder_high_fn(req_in);
    assign code_low = encoder_low_fn(req_in, code_high);
    
    always @(posedge clk) begin
        if (rst) begin
            // 重置所有流水线寄存器
            req_pipe1 <= 0;
            req_pipe2 <= 0;
            req_pipe3 <= 0;
            req_pipe4 <= 0;
            
            code_high_reg <= 5'h1F;
            code_low_reg <= 5'h1F;
            code_stage1 <= 5'h1F;
            code_stage2 <= 5'h1F;
            code_stage3 <= 5'h1F;
            
            has_req_pipe1 <= 1'b0;
            has_req_pipe2 <= 1'b0;
            has_req_pipe3 <= 1'b0;
            has_req_pipe4 <= 1'b0;
            
            grant_out <= 5'h1F;
            h1F_const <= 5'h1F;
        end else begin
            // 更新常量缓冲
            h1F_const <= 5'h1F;
            
            // 输入端已经将组合逻辑前移，直接寄存计算结果
            code_high_reg <= code_high;
            code_low_reg <= code_low;
            req_pipe1 <= req_in;
            has_req_pipe1 <= |req_in;
            
            // Pipeline stage 2
            req_pipe2 <= req_pipe1;
            code_stage1 <= has_req_pipe1 ? code_low_reg : 5'h1F;
            has_req_pipe2 <= has_req_pipe1;
            
            // Pipeline stage 3
            req_pipe3 <= req_pipe2;
            code_stage2 <= code_stage1;
            has_req_pipe3 <= has_req_pipe2;
            
            // Pipeline stage 4
            req_pipe4 <= req_pipe3;
            code_stage3 <= code_stage2;
            has_req_pipe4 <= has_req_pipe3;
            
            // Pipeline stage 5 - 输出
            grant_out <= has_req_pipe4 ? code_stage3 : h1F_const;
        end
    end
endmodule