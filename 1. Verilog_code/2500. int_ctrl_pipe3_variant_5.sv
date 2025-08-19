//SystemVerilog
module int_ctrl_pipe3 #(
    parameter WIDTH = 16
)(
    input clk, rst,
    input [WIDTH-1:0] req_in,
    output reg [4:0] grant_out
);
    // Pre-compute the encoded request directly from inputs
    wire [4:0] encoded_req;
    wire req_valid;
    
    // Optimized pipeline structure with smaller always blocks
    reg [WIDTH-1:0] req_stage2;
    reg [4:0] code_stage1, code_stage2;
    reg req_valid_stage1, req_valid_stage2;
    
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
    
    // Combinational logic moved before first register stage
    assign encoded_req = encoder(req_in);
    assign req_valid = |req_in; // 优化：使用OR reduction运算符
    
    // 将大的always块分解为多个小的always块
    
    // Pipeline stage 1 - code_stage1 寄存器
    always @(posedge clk) begin
        if (rst) begin
            code_stage1 <= 5'h1F;
        end else begin
            code_stage1 <= encoded_req;
        end
    end
    
    // Pipeline stage 1 - req_valid_stage1 寄存器
    always @(posedge clk) begin
        if (rst) begin
            req_valid_stage1 <= 1'b0;
        end else begin
            req_valid_stage1 <= req_valid;
        end
    end
    
    // Pipeline stage 2 - req_stage2 寄存器
    always @(posedge clk) begin
        if (rst) begin
            req_stage2 <= {WIDTH{1'b0}}; // 使用参数化复位值
        end else begin
            req_stage2 <= req_in;
        end
    end
    
    // Pipeline stage 2 - code_stage2 寄存器
    always @(posedge clk) begin
        if (rst) begin
            code_stage2 <= 5'h1F;
        end else begin
            code_stage2 <= code_stage1;
        end
    end
    
    // Pipeline stage 2 - req_valid_stage2 寄存器
    always @(posedge clk) begin
        if (rst) begin
            req_valid_stage2 <= 1'b0;
        end else begin
            req_valid_stage2 <= req_valid_stage1;
        end
    end
    
    // Pipeline stage 3 - grant_out 寄存器
    always @(posedge clk) begin
        if (rst) begin
            grant_out <= 5'h1F;
        end else begin
            grant_out <= req_valid_stage2 ? code_stage2 : 5'h1F;
        end
    end
endmodule