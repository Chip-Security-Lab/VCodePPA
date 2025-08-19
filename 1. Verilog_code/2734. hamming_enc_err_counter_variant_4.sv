//SystemVerilog
module hamming_enc_err_counter(
    input clk, rst,
    input valid_in,               // 取代原来的en, 表示输入数据有效
    output reg ready_in,          // 新增信号, 表示模块准备好接收新数据
    input [3:0] data_in,          // 输入数据
    input error_inject,           // 错误注入信号
    output reg [6:0] encoded,     // 编码后的数据
    output reg valid_out,         // 新增信号, 表示输出数据有效
    input ready_out,              // 新增信号, 表示下游模块准备好接收
    output reg [7:0] error_count  // 错误计数器
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam WAITING = 2'b10;
    
    reg [1:0] state, next_state;
    reg [3:0] data_reg;
    reg error_inject_reg;
    reg data_valid;
    
    // 预计算编码位
    wire [6:0] encoded_next;
    wire [6:0] encoded_error;
    
    // 预计算编码位 - 减少关键路径上的组合逻辑
    assign encoded_next[0] = data_reg[0] ^ data_reg[1] ^ data_reg[3];
    assign encoded_next[1] = data_reg[0] ^ data_reg[2] ^ data_reg[3];
    assign encoded_next[2] = data_reg[0];
    assign encoded_next[3] = data_reg[1] ^ data_reg[2] ^ data_reg[3];
    assign encoded_next[4] = data_reg[1];
    assign encoded_next[5] = data_reg[2];
    assign encoded_next[6] = data_reg[3];
    
    // 预计算错误注入编码位
    assign encoded_error[0] = ~encoded_next[0];
    assign encoded_error[1] = encoded_next[1];
    assign encoded_error[2] = encoded_next[2];
    assign encoded_error[3] = encoded_next[3];
    assign encoded_error[4] = encoded_next[4];
    assign encoded_error[5] = encoded_next[5];
    assign encoded_error[6] = encoded_next[6];
    
    // 状态转换逻辑 - 使用非阻塞赋值提高时序性能
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 下一状态逻辑和控制信号生成 - 优化条件判断链
    always @(*) begin
        // 默认值设置
        next_state = state;
        ready_in = 1'b0;
        
        // 使用优先级编码器风格优化状态转换
        if (state == IDLE) begin
            ready_in = 1'b1;
            if (valid_in) begin
                next_state = PROCESSING;
            end
        end else if (state == PROCESSING) begin
            next_state = WAITING;
        end else if (state == WAITING) begin
            if (ready_out && valid_out) begin
                next_state = IDLE;
            end
        end else begin
            next_state = IDLE;
        end
    end
    
    // 数据寄存和处理 - 优化数据路径
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_reg <= 4'b0;
            error_inject_reg <= 1'b0;
            data_valid <= 1'b0;
        end else if (state == IDLE && valid_in) begin
            data_reg <= data_in;
            error_inject_reg <= error_inject;
            data_valid <= 1'b1;
        end else if (state == WAITING && ready_out && valid_out) begin
            data_valid <= 1'b0;
        end
    end
    
    // 编码逻辑 - 使用预计算值减少关键路径
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            error_count <= 8'b0;
            valid_out <= 1'b0;
        end else if (state == PROCESSING && data_valid) begin
            // 使用预计算值减少关键路径上的组合逻辑
            encoded <= error_inject_reg ? encoded_error : encoded_next;
            
            // 错误计数逻辑优化
            if (error_inject_reg) begin
                error_count <= error_count + 1;
            end
            
            valid_out <= 1'b1;
        end else if (state == WAITING && ready_out && valid_out) begin
            valid_out <= 1'b0;
        end
    end
endmodule