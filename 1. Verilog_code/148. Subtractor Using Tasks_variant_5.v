module subtractor_valid_ready (
    input wire clk,           // 时钟信号
    input wire rst_n,         // 复位信号，低电平有效
    
    // 输入接口
    input wire [7:0] a,       // 被减数
    input wire a_valid,       // 输入数据有效信号
    output reg a_ready,       // 输入数据就绪信号
    
    // 输出接口
    output reg [7:0] res,     // 差
    output reg res_valid,     // 输出数据有效信号
    input wire res_ready      // 输出数据就绪信号
);

// 内部状态定义
localparam IDLE = 2'b00;
localparam CALC = 2'b01;
localparam WAIT = 2'b10;

reg [1:0] state, next_state;
reg [7:0] a_reg, b_reg;      // 输入寄存器
reg [7:0] b_comp;            // 减数的补码
reg [7:0] sum;               // 中间和
reg calc_done;               // 计算完成标志

// 状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

// 下一状态逻辑
always @(*) begin
    next_state = state;
    
    case (state)
        IDLE: begin
            if (a_valid && a_ready)
                next_state = CALC;
        end
        
        CALC: begin
            next_state = WAIT;
        end
        
        WAIT: begin
            if (res_valid && res_ready)
                next_state = IDLE;
        end
        
        default: next_state = IDLE;
    endcase
end

// 输出逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_ready <= 1'b0;
        res_valid <= 1'b0;
        res <= 8'b0;
        a_reg <= 8'b0;
        b_reg <= 8'b0;
        calc_done <= 1'b0;
    end
    else begin
        case (state)
            IDLE: begin
                a_ready <= 1'b1;
                res_valid <= 1'b0;
                
                if (a_valid && a_ready) begin
                    a_reg <= a;
                    b_reg <= a;  // 假设b是a的副本，根据实际需求修改
                end
            end
            
            CALC: begin
                a_ready <= 1'b0;
                res_valid <= 1'b0;
                
                // 计算减法
                b_comp <= ~b_reg + 1'b1;  // 计算减数的补码
                sum <= a_reg + b_comp;    // 使用补码加法实现减法
                res <= sum;               // 输出结果
                calc_done <= 1'b1;
            end
            
            WAIT: begin
                a_ready <= 1'b0;
                res_valid <= 1'b1;
                
                if (res_valid && res_ready) begin
                    res_valid <= 1'b0;
                    calc_done <= 1'b0;
                end
            end
            
            default: begin
                a_ready <= 1'b0;
                res_valid <= 1'b0;
            end
        endcase
    end
end

endmodule