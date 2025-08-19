//SystemVerilog
module rle_codec (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg data_ready,
    output reg [7:0] data_out,
    output reg data_out_valid
);

    // 优化状态编码以减少状态转换逻辑
    localparam IDLE        = 2'b00;
    localparam COUNT_LOAD  = 2'b01;
    localparam DATA_PROCESS = 2'b10;
    
    // 内部寄存器和状态信号
    reg [1:0] current_state, next_state;
    reg [7:0] count_reg;
    reg [7:0] data_in_reg;
    reg is_control_code;
    
    // 输入数据捕获和标志处理 - 优化了决策逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 8'h0;
            is_control_code <= 1'b0;
            data_ready <= 1'b1;
        end 
        else begin
            // 条件合并和重排序以减少比较路径
            if (current_state == IDLE) begin
                data_ready <= 1'b1;
                if (data_valid) begin
                    data_in_reg <= data_in;
                    is_control_code <= data_in[7];
                    data_ready <= 1'b0;
                end
            end
        end
    end
    
    // 状态转换 - 使用非阻塞赋值提高时序性能
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end 
        else begin
            current_state <= next_state;
        end
    end
    
    // 状态转换逻辑 - 优化比较链
    always @(*) begin
        // 默认状态赋值减少锁存器生成
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (data_valid && data_ready)
                    next_state = COUNT_LOAD;
            end
            
            COUNT_LOAD: begin
                next_state = DATA_PROCESS;
            end
            
            DATA_PROCESS: begin
                // 使用范围检测优化条件判断
                if (count_reg <= 8'h1 || !is_control_code)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 计数器处理 - 简化逻辑结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg <= 8'h0;
        end 
        else begin
            case (current_state)
                COUNT_LOAD:
                    count_reg <= is_control_code ? {1'b0, data_in_reg[6:0]} : 8'h1;
                
                DATA_PROCESS:
                    if (count_reg > 8'h0)
                        count_reg <= count_reg - 8'h1;
                
                default: ;  // 保持当前值
            endcase
        end
    end
    
    // 输出数据生成 - 优化条件逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h0;
            data_out_valid <= 1'b0;
        end 
        else begin
            // 默认值设置减少逻辑资源
            data_out_valid <= (current_state == DATA_PROCESS);
            
            if (current_state == DATA_PROCESS)
                data_out <= is_control_code ? 8'h0 : data_in_reg;
        end
    end

endmodule