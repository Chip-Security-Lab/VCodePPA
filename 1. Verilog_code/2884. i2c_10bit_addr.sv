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
    
    // 定义状态
    localparam IDLE = 2'b00;
    localparam ADDR_PHASE1 = 2'b01;
    localparam ADDR_PHASE2 = 2'b10;
    localparam DATA_PHASE = 2'b11;
    
    reg [1:0] state;
    
    // 状态机实现
    always @(posedge clk or posedge rst_sync) begin
        if (rst_sync) begin
            state <= IDLE;
            addr_shift <= 10'h0;
            addr_phase <= 1'b0;
            addr_valid <= 1'b0;
            shift_reg <= 8'h0;
        end else begin
            case(state)
                IDLE: begin
                    // 等待起始条件
                    if (sda == 1'b0 && scl == 1'b1) begin
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
                        // 7位地址模式
                        addr_valid <= (shift_reg[7:1] == target_addr[6:0]);
                        state <= DATA_PHASE;
                    end else begin
                        // 10位地址模式
                        if (shift_reg[7:3] == 5'b11110) begin
                            state <= ADDR_PHASE2;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end
                
                ADDR_PHASE2: begin
                    // 接收第二个地址字节 (10位模式)
                    addr_shift[1:0] <= shift_reg[7:6];
                    addr_valid <= (addr_shift[9:2] == target_addr[9:2] && 
                                  shift_reg[7:6] == target_addr[1:0]);
                    state <= DATA_PHASE;
                end
                
                DATA_PHASE: begin
                    // 处理数据阶段
                    if (sda == 1'b0 && scl == 1'b0) begin
                        state <= IDLE; // 检测到停止条件
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // I2C数据接收逻辑 (简化版)
    reg [2:0] bit_count;
    always @(posedge scl) begin
        if (state != IDLE) begin
            shift_reg <= {shift_reg[6:0], sda};
            bit_count <= bit_count + 1;
            
            if (bit_count == 3'b111) begin
                bit_count <= 3'b000;
            end
        end else begin
            bit_count <= 3'b000;
        end
    end
endmodule