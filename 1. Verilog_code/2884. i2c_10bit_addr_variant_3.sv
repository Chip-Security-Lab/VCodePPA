//SystemVerilog
module i2c_10bit_addr #(
    parameter ADDR_MODE = 0  // 0-7bit, 1-10bit
)(
    input clk,
    input rst_sync,
    inout sda,
    inout scl,
    input [9:0] target_addr,
    output reg addr_valid
);
    // 混合地址模式支持
    reg [9:0] addr_shift;
    reg addr_phase;
    reg [7:0] shift_reg;
    
    // 定义状态 - 使用独热编码提高性能
    localparam IDLE       = 4'b0001;
    localparam ADDR_PHASE1 = 4'b0010;
    localparam ADDR_PHASE2 = 4'b0100;
    localparam DATA_PHASE  = 4'b1000;
    
    reg [3:0] state;
    
    // 优化的地址比较逻辑
    wire addr7bit_match = (shift_reg[7:1] == target_addr[6:0]);
    wire addr10bit_prefix_valid = (shift_reg[7:3] == 5'b11110);
    wire addr10bit_match = (addr_shift[9:2] == target_addr[9:2]) && 
                           (shift_reg[7:6] == target_addr[1:0]);
    
    // 状态转换条件
    wire start_condition = (sda == 1'b0) && (scl == 1'b1);
    wire stop_condition = (sda == 1'b0) && (scl == 1'b0);
    
    // 状态机实现 - 优化的结构
    always @(posedge clk or posedge rst_sync) begin
        if (rst_sync) begin
            state <= IDLE;
            addr_shift <= 10'h0;
            addr_phase <= 1'b0;
            addr_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_condition) begin
                        state <= ADDR_PHASE1;
                        addr_phase <= 1'b0;
                        addr_valid <= 1'b0;
                    end
                end
                
                ADDR_PHASE1: begin
                    // 接收第一个地址字节
                    addr_shift[9:2] <= shift_reg;
                    addr_phase <= 1'b1;
                    
                    if (ADDR_MODE == 0) begin
                        // 7位地址模式 - 优化比较链
                        addr_valid <= addr7bit_match;
                        state <= DATA_PHASE;
                    end else if (addr10bit_prefix_valid) begin
                        // 10位地址模式，前缀正确
                        state <= ADDR_PHASE2;
                    end else begin
                        // 10位地址模式，前缀错误
                        state <= IDLE;
                    end
                end
                
                ADDR_PHASE2: begin
                    // 接收第二个地址字节 (10位模式)
                    addr_shift[1:0] <= shift_reg[7:6];
                    addr_valid <= addr10bit_match;
                    state <= DATA_PHASE;
                end
                
                DATA_PHASE: begin
                    if (stop_condition) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // I2C数据接收逻辑 - 优化的计数器和移位寄存器
    reg [2:0] bit_count;
    always @(posedge scl) begin
        if (state == IDLE) begin
            bit_count <= 3'b000;
            shift_reg <= 8'h0;
        end else begin
            shift_reg <= {shift_reg[6:0], sda};
            bit_count <= (bit_count == 3'b111) ? 3'b000 : bit_count + 1'b1;
        end
    end
endmodule