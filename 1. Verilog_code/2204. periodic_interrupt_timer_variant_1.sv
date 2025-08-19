//SystemVerilog, IEEE 1364-2005
module periodic_interrupt_timer #(
    parameter COUNT_WIDTH = 24
)(
    input  wire                  sysclk,
    input  wire                  nreset,
    input  wire [COUNT_WIDTH-1:0] reload_value,
    input  wire                  timer_en,
    output reg                   intr_req,
    output wire [COUNT_WIDTH-1:0] current_value
);
    // 主计数器
    reg [COUNT_WIDTH-1:0] counter;
    // 计数器缓冲寄存器 - 用于减少高扇出负载
    reg [COUNT_WIDTH-1:0] counter_buf1, counter_buf2;
    
    // 为current_value输出使用缓冲寄存器
    assign current_value = counter_buf1;
    
    // 定义状态标志，用于case语句
    reg [1:0] timer_state;
    // 状态标志缓冲寄存器 - 用于减少高扇出负载
    reg [1:0] timer_state_buf1, timer_state_buf2;
    
    wire counter_zero;
    
    // 计数器是否为零 - 使用缓冲后的计数器值
    assign counter_zero = (counter_buf2 == {COUNT_WIDTH{1'b0}});
    
    // 更新缓冲寄存器 - 采用多级缓冲以平衡各路径延迟
    always @(posedge sysclk or negedge nreset) begin
        if (!nreset) begin
            counter_buf1 <= {COUNT_WIDTH{1'b1}};
            counter_buf2 <= {COUNT_WIDTH{1'b1}};
            timer_state_buf1 <= 2'b00;
            timer_state_buf2 <= 2'b00;
        end
        else begin
            counter_buf1 <= counter;
            counter_buf2 <= counter_buf1;
            timer_state_buf1 <= timer_state;
            timer_state_buf2 <= timer_state_buf1;
        end
    end
    
    // 生成状态标志：组合timer_en和counter_zero
    always @(*) begin
        if (!timer_en)
            timer_state = 2'b00;  // 定时器禁用
        else if (counter_zero)
            timer_state = 2'b01;  // 定时器启用且计数器为零
        else
            timer_state = 2'b10;  // 定时器启用且计数器非零
    end
    
    // 主状态机 - 使用缓冲后的状态信号
    always @(posedge sysclk or negedge nreset) begin
        if (!nreset) begin
            counter <= {COUNT_WIDTH{1'b1}};
            intr_req <= 1'b0;
        end
        else begin
            case (timer_state_buf2)
                2'b00: begin  // 定时器禁用
                    intr_req <= 1'b0;
                end
                
                2'b01: begin  // 定时器启用且计数器为零
                    counter <= reload_value;
                    intr_req <= 1'b1;
                end
                
                2'b10: begin  // 定时器启用且计数器非零
                    counter <= counter - 1'b1;
                    intr_req <= 1'b0;
                end
                
                default: begin  // 安全默认状态
                    intr_req <= 1'b0;
                end
            endcase
        end
    end
endmodule