//SystemVerilog
// SystemVerilog IEEE 1364-2005
module i2c_encoder (
    input wire clk,
    input wire rst_n,      // 添加异步复位
    input wire start,
    input wire stop,
    input wire [7:0] addr,
    input wire [7:0] data,
    output wire sda,
    output wire scl,
    output wire ack,
    output wire ready      // 流水线就绪信号
);
    // 流水线阶段参数
    parameter IDLE = 3'd0, START_STAGE = 3'd1, ADDR_STAGE = 3'd2, DATA_STAGE = 3'd3, STOP_STAGE = 3'd4;
    
    // 流水线寄存器
    reg [2:0] state_stage1, state_stage2, state_stage3;
    reg [3:0] bit_cnt_stage1, bit_cnt_stage2, bit_cnt_stage3;
    reg ack_stage1, ack_stage2, ack_stage3;
    
    // 数据寄存器
    reg [7:0] addr_stage1, addr_stage2, addr_stage3;
    reg [7:0] data_stage1, data_stage2, data_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    reg start_stage1, start_stage2, start_stage3;
    reg stop_stage1, stop_stage2, stop_stage3;
    
    // 输出寄存器
    reg sda_stage1, sda_stage2, sda_stage3;
    reg scl_stage1, scl_stage2, scl_stage3;
    
    // 流水线阶段1: 状态计算和控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            bit_cnt_stage1 <= 4'h0;
            ack_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            start_stage1 <= 1'b0;
            stop_stage1 <= 1'b0;
            addr_stage1 <= 8'h0;
            data_stage1 <= 8'h0;
        end else begin
            // 捕获输入
            start_stage1 <= start;
            stop_stage1 <= stop;
            addr_stage1 <= addr;
            data_stage1 <= data;
            
            // 默认保持状态
            valid_stage1 <= 1'b1;
            
            if (start) begin
                state_stage1 <= START_STAGE;
                bit_cnt_stage1 <= 4'h0;
                ack_stage1 <= 1'b0;
            end else begin
                case(state_stage1)
                    IDLE: begin
                        if (start) state_stage1 <= START_STAGE;
                        valid_stage1 <= start;
                    end
                    START_STAGE: begin
                        state_stage1 <= ADDR_STAGE;
                    end
                    ADDR_STAGE: begin
                        if (bit_cnt_stage1 < 8) begin
                            if (scl_stage3) bit_cnt_stage1 <= bit_cnt_stage1 + 1;
                        end else begin
                            state_stage1 <= DATA_STAGE;
                            bit_cnt_stage1 <= 4'h0;
                            ack_stage1 <= 1'b1;
                        end
                    end
                    DATA_STAGE: begin
                        if (bit_cnt_stage1 < 8) begin
                            if (scl_stage3) bit_cnt_stage1 <= bit_cnt_stage1 + 1;
                        end else if (stop_stage1) begin
                            state_stage1 <= STOP_STAGE;
                            ack_stage1 <= 1'b1;
                        end else begin
                            bit_cnt_stage1 <= 4'h0;
                            ack_stage1 <= 1'b1;
                        end
                    end
                    STOP_STAGE: begin
                        state_stage1 <= IDLE;
                        valid_stage1 <= 1'b0;
                    end
                    default: state_stage1 <= IDLE;
                endcase
            end
        end
    end
    
    // 流水线阶段2: SCL生成逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_stage2 <= 1'b1;
            state_stage2 <= IDLE;
            bit_cnt_stage2 <= 4'h0;
            ack_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            start_stage2 <= 1'b0;
            stop_stage2 <= 1'b0;
            addr_stage2 <= 8'h0;
            data_stage2 <= 8'h0;
        end else begin
            // 传递阶段1的数据到阶段2
            state_stage2 <= state_stage1;
            bit_cnt_stage2 <= bit_cnt_stage1;
            ack_stage2 <= ack_stage1;
            valid_stage2 <= valid_stage1;
            start_stage2 <= start_stage1;
            stop_stage2 <= stop_stage1;
            addr_stage2 <= addr_stage1;
            data_stage2 <= data_stage1;
            
            // SCL生成逻辑
            case(state_stage1)
                IDLE: begin
                    scl_stage2 <= 1'b1;
                end
                START_STAGE: begin
                    scl_stage2 <= 1'b0;
                end
                ADDR_STAGE: begin
                    if (bit_cnt_stage1 < 8) begin
                        scl_stage2 <= ~scl_stage3;
                    end
                end
                DATA_STAGE: begin
                    if (bit_cnt_stage1 < 8) begin
                        scl_stage2 <= ~scl_stage3;
                    end
                end
                STOP_STAGE: begin
                    scl_stage2 <= 1'b1;
                end
            endcase
        end
    end
    
    // 流水线阶段3: SDA生成逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_stage3 <= 1'b1;
            scl_stage3 <= 1'b1;
            state_stage3 <= IDLE;
            bit_cnt_stage3 <= 4'h0;
            ack_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            start_stage3 <= 1'b0;
            stop_stage3 <= 1'b0;
            addr_stage3 <= 8'h0;
            data_stage3 <= 8'h0;
        end else begin
            // 传递阶段2的数据到阶段3
            state_stage3 <= state_stage2;
            bit_cnt_stage3 <= bit_cnt_stage2;
            ack_stage3 <= ack_stage2;
            valid_stage3 <= valid_stage2;
            start_stage3 <= start_stage2;
            stop_stage3 <= stop_stage2;
            addr_stage3 <= addr_stage2;
            data_stage3 <= data_stage2;
            scl_stage3 <= scl_stage2;
            
            // SDA生成逻辑
            case(state_stage2)
                IDLE: begin
                    sda_stage3 <= 1'b1;
                end
                START_STAGE: begin
                    sda_stage3 <= 1'b0;
                end
                ADDR_STAGE: begin
                    if (bit_cnt_stage2 < 8) begin
                        sda_stage3 <= addr_stage2[7 - bit_cnt_stage2];
                    end
                end
                DATA_STAGE: begin
                    if (bit_cnt_stage2 < 8) begin
                        sda_stage3 <= data_stage2[7 - bit_cnt_stage2];
                    end
                end
                STOP_STAGE: begin
                    sda_stage3 <= 1'b1;
                end
            endcase
        end
    end
    
    // 输出赋值
    assign sda = sda_stage3;
    assign scl = scl_stage3;
    assign ack = ack_stage3;
    assign ready = (state_stage1 == IDLE) && !valid_stage1;
endmodule