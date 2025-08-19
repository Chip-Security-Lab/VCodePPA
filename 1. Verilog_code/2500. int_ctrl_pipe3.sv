module int_ctrl_pipe3 #(
    parameter WIDTH = 16
)(
    input clk, rst,
    input [WIDTH-1:0] req_in,
    output reg [4:0] grant_out
);
    reg [WIDTH-1:0] req_stage1, req_stage2;
    reg [4:0] code_stage1, code_stage2;
    
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
    
    always @(posedge clk) begin
        if (rst) begin
            req_stage1 <= 0;
            req_stage2 <= 0;
            code_stage1 <= 5'h1F;
            code_stage2 <= 5'h1F;
            grant_out <= 5'h1F;
        end else begin
            // Pipeline stage 1
            req_stage1 <= req_in;
            code_stage1 <= encoder(req_in);
            
            // Pipeline stage 2
            req_stage2 <= req_stage1;
            code_stage2 <= code_stage1;
            
            // Pipeline stage 3
            grant_out <= (req_stage2 != 0) ? code_stage2 : 5'h1F;
        end
    end
endmodule