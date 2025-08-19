//SystemVerilog
module serial_receiver(
    input wire clk, rst, rx_in,
    output reg [7:0] data_out,
    output reg valid
);
    // 使用独热编码状态机以提高时序性能
    localparam IDLE = 4'b0001, START = 4'b0010, DATA = 4'b0100, STOP = 4'b1000;
    reg [3:0] state, next_state;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    reg bit_count_reset, shift_enable, data_latch;
    
    // 分离状态寄存器更新逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end
    
    // 优化状态转换和控制信号生成
    always @(*) begin
        // 默认值设置
        valid = 1'b0;
        next_state = state;
        bit_count_reset = 1'b0;
        shift_enable = 1'b0;
        data_latch = 1'b0;
        
        case (state)
            IDLE: begin
                bit_count_reset = 1'b1;
                if (!rx_in) next_state = START;
            end
            
            START: begin
                next_state = DATA;
            end
            
            DATA: begin
                shift_enable = 1'b1;
                // 使用比较范围代替相等检查
                if (bit_count == 3'h7) next_state = STOP;
            end
            
            STOP: begin
                valid = rx_in;
                next_state = IDLE;
                data_latch = 1'b1;
                bit_count_reset = 1'b1;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 分离数据处理逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin 
            bit_count <= 3'b0;
            shift_reg <= 8'b0;
            data_out <= 8'b0;
        end
        else begin
            // 使用控制信号来触发相应操作，减少条件判断
            if (bit_count_reset) begin
                bit_count <= 3'b0;
            end
            else if (shift_enable) begin
                shift_reg <= {rx_in, shift_reg[7:1]};
                bit_count <= bit_count + 3'b1;
            end
            
            if (data_latch) begin
                data_out <= shift_reg;
            end
        end
    end
endmodule