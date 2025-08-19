//SystemVerilog
module RoundRobinArbiter #(parameter WIDTH=8) (
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] req,
    output reg [WIDTH-1:0] grant
);
    // 优先级指针和请求处理
    reg [WIDTH-1:0] pointer;        // 优先级指针
    reg [WIDTH-1:0] masked_req;     // 掩码后的请求信号
    reg [WIDTH-1:0] req_reg;        // 寄存器化请求信号
    
    // 第一级：注册输入请求信号
    always @(posedge clk) begin
        if (rst)
            req_reg <= {WIDTH{1'b0}};
        else
            req_reg <= req;
    end
    
    // 第二级：优先级指针移位逻辑
    always @(posedge clk) begin
        if (rst)
            pointer <= {{WIDTH-1{1'b0}}, 1'b1};  // 初始化为首位为1，其余为0
        else if (|req_reg)  // 只有当有请求时才旋转指针
            pointer <= {pointer[WIDTH-2:0], pointer[WIDTH-1]};
    end
    
    // 第三级：使用掩码计算授权决策
    always @(posedge clk) begin
        if (rst)
            masked_req <= {WIDTH{1'b0}};
        else
            masked_req <= req_reg & pointer;
    end
    
    // 第四级：生成最终授权信号，使用二进制补码减法
    always @(posedge clk) begin
        if (rst)
            grant <= {WIDTH{1'b0}};
        else if (|masked_req)
            grant <= masked_req;
        else if (|req_reg)  // 当掩码请求为0但有请求时，选择第一个请求
            grant <= req_reg & (~(req_reg + 1'b1) & req_reg); // 使用补码减法
        else
            grant <= {WIDTH{1'b0}};
    end

endmodule