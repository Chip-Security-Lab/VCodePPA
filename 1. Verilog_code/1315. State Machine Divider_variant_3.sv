//SystemVerilog
module fsm_divider (
    input  wire       clk_input,  // 输入时钟信号
    input  wire       reset,      // 复位信号，高电平有效
    input  wire       ready,      // 接收方准备好接收数据
    output wire       valid,      // 数据有效信号
    output wire       clk_output  // 输出时钟信号
);
    // 状态编码定义
    localparam [1:0] S0 = 2'b00, 
                     S1 = 2'b01, 
                     S2 = 2'b10, 
                     S3 = 2'b11;
    
    // 状态寄存器
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    // 输出寄存器
    reg clk_output_reg;
    reg valid_reg;
    
    // 阶段1: 状态转移逻辑 - 同步状态更新
    always @(posedge clk_input or posedge reset) begin
        if (reset) begin
            current_state <= S0;
        end else if (ready || !valid_reg) begin
            current_state <= next_state;
        end
    end
    
    // 阶段2: 下一状态组合逻辑 - 状态转换路径
    always @(*) begin
        case (current_state)
            S0:      next_state = S1;
            S1:      next_state = S2;
            S2:      next_state = S3;
            S3:      next_state = S0;
            default: next_state = S0;
        endcase
    end
    
    // 阶段3: 输出逻辑 - 时钟分频输出和valid信号
    always @(posedge clk_input or posedge reset) begin
        if (reset) begin
            clk_output_reg <= 1'b0;
            valid_reg <= 1'b0;
        end else begin
            clk_output_reg <= (next_state == S0 || next_state == S1);
            
            if (ready && valid_reg) begin
                // 握手完成，重置valid信号
                valid_reg <= 1'b0;
            end else if (!valid_reg) begin
                // 设置valid信号表示新数据有效
                valid_reg <= 1'b1;
            end
        end
    end
    
    // 输出分配
    assign clk_output = clk_output_reg;
    assign valid = valid_reg;
    
endmodule