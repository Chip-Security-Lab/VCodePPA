//SystemVerilog
module hybrid_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // 优先级和请求分组
    wire [1:0] high_priority_req;
    wire [1:0] low_priority_req;
    wire high_priority_valid;
    
    // 轮询指针寄存器
    reg [1:0] rr_ptr;
    reg [1:0] next_rr_ptr;
    
    // 流水线寄存器阶段1 - 请求和状态寄存
    reg [WIDTH-1:0] req_i_pipe;
    reg [1:0] rr_ptr_pipe;
    reg high_priority_valid_pipe;
    reg [1:0] high_priority_req_pipe;
    reg [1:0] low_priority_req_pipe;
    
    // 流水线寄存器阶段2 - 中间结果
    reg [WIDTH-1:0] next_grant;
    
    // 优先级和请求分组
    assign high_priority_req = req_i[3:2];
    assign low_priority_req = req_i[1:0];
    assign high_priority_valid = |high_priority_req;
    
    // 第一级流水线 - 寄存请求和状态信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_i_pipe <= {WIDTH{1'b0}};
            rr_ptr_pipe <= 2'b00;
            high_priority_valid_pipe <= 1'b0;
            high_priority_req_pipe <= 2'b00;
            low_priority_req_pipe <= 2'b00;
        end
        else begin
            req_i_pipe <= req_i;
            rr_ptr_pipe <= rr_ptr;
            high_priority_valid_pipe <= high_priority_valid;
            high_priority_req_pipe <= high_priority_req;
            low_priority_req_pipe <= low_priority_req;
        end
    end
    
    // 仲裁逻辑 - 使用流水线寄存的信号
    always @(*) begin
        // 默认值
        next_grant = 4'b0000;
        next_rr_ptr = rr_ptr_pipe;
        
        // 高优先级仲裁逻辑
        if (high_priority_req_pipe[0]) begin
            // req_i[2]有最高优先级
            next_grant = 4'b0100;
        end
        else if (high_priority_req_pipe[1]) begin
            // req_i[3]有次高优先级
            next_grant = 4'b1000;
        end
        // 低优先级轮询仲裁逻辑
        else if (!high_priority_valid_pipe) begin
            // 只有在没有高优先级请求时才考虑低优先级
            if (low_priority_req_pipe[(rr_ptr_pipe + 0) % 2]) begin
                next_grant = 1 << ((rr_ptr_pipe + 0) % 2);
                next_rr_ptr = (rr_ptr_pipe + 1) % 2;
            end
            else if (low_priority_req_pipe[(rr_ptr_pipe + 1) % 2]) begin
                next_grant = 1 << ((rr_ptr_pipe + 1) % 2);
                next_rr_ptr = (rr_ptr_pipe + 2) % 2;
            end
        end
    end
    
    // 时序逻辑 - 更新状态和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
            rr_ptr <= 2'b00;
        end
        else begin
            grant_o <= next_grant;
            rr_ptr <= next_rr_ptr;
        end
    end
endmodule