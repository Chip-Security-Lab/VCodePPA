//SystemVerilog
module int_ctrl_pipe3 #(
    parameter WIDTH = 16
)(
    input clk, rst,
    input [WIDTH-1:0] req_in,
    output reg [4:0] grant_out
);
    wire [4:0] encoded_req;
    reg [WIDTH-1:0] req_stage2;
    reg [4:0] code_stage2;
    
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
    
    // 将编码逻辑移出寄存器，实现前向重定时
    assign encoded_req = encoder(req_in);
    
    always @(posedge clk) begin
        if (rst) begin
            req_stage2 <= 0;
            code_stage2 <= 5'h1F;
            grant_out <= 5'h1F;
        end else begin
            // 移除第一级流水线寄存器，将编码逻辑前移
            // Pipeline stage 2 (原来的stage1被移除)
            req_stage2 <= req_in;
            code_stage2 <= encoded_req;
            
            // Pipeline stage 3
            grant_out <= (req_stage2 != 0) ? code_stage2 : 5'h1F;
        end
    end
endmodule