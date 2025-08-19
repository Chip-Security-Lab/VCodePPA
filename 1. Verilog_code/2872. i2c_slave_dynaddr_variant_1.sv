//SystemVerilog - IEEE 1364-2005 Verilog标准
module i2c_slave_dynaddr #(
    parameter FILTER_WIDTH = 3  // 输入滤波器参数
)(
    input clk,
    input rst_n,
    input scl,
    inout sda,
    output reg [7:0] data_out,
    output reg data_valid,
    input [7:0] data_in,
    input [6:0] slave_addr
);

// 流水线阶段1：输入滤波
wire scl_in = scl;
wire sda_in = sda;
reg [FILTER_WIDTH-1:0] scl_filter;
reg [FILTER_WIDTH-1:0] sda_filter;
reg scl_filtered_stage1, sda_filtered_stage1;
reg valid_stage1;

// 流水线阶段2：边沿检测
reg scl_filtered_stage2, sda_filtered_stage2;
reg scl_prev_stage2, sda_prev_stage2;
reg scl_rising_stage2, scl_falling_stage2;
reg sda_rising_stage2, sda_falling_stage2;
reg valid_stage2;

// 流水线阶段3：状态处理
reg scl_filtered_stage3, sda_filtered_stage3;
reg [7:0] shift_reg_stage3;
reg [2:0] bit_cnt_stage3;
reg addr_match_stage3;
reg valid_stage3;
reg start_detected_stage3, stop_detected_stage3;
reg [3:0] state_stage3;

// 流水线阶段4：数据处理和输出
reg [7:0] shift_reg_stage4;
reg [2:0] bit_cnt_stage4;
reg addr_match_stage4;
reg valid_stage4;
reg [3:0] state_stage4;
reg sda_out_en;
reg sda_out_val;

// 并行前缀减法器信号定义
reg [7:0] subtrahend, minuend;
wire [7:0] difference;
wire [7:0] borrow_generate, borrow_propagate;
wire [7:0] borrow_chain;

// 内部状态定义
localparam IDLE = 4'd0;
localparam START = 4'd1;
localparam ADDR = 4'd2;
localparam ACK_ADDR = 4'd3;
localparam READ = 4'd4;
localparam WRITE = 4'd5;
localparam ACK_READ = 4'd6;
localparam ACK_WRITE = 4'd7;
localparam STOP = 4'd8;

// 双向SDA控制
assign sda = sda_out_en ? sda_out_val : 1'bz;

// 流水线阶段1：输入滤波
always @(posedge clk) begin
    if (!rst_n) begin
        scl_filter <= {FILTER_WIDTH{1'b0}};
        sda_filter <= {FILTER_WIDTH{1'b0}};
        scl_filtered_stage1 <= 1'b1;
        sda_filtered_stage1 <= 1'b1;
        valid_stage1 <= 1'b0;
    end else begin
        // 滤波器寄存器直接连接到输入
        scl_filter <= {scl_filter[FILTER_WIDTH-2:0], scl_in};
        sda_filter <= {sda_filter[FILTER_WIDTH-2:0], sda_in};
        
        // 多数表决滤波
        scl_filtered_stage1 <= (^scl_filter) ? 1'b1 : 1'b0;
        sda_filtered_stage1 <= (^sda_filter) ? 1'b1 : 1'b0;
        valid_stage1 <= 1'b1; // 始终有效，除了复位后第一个周期
    end
end

// 流水线阶段2：边沿检测
always @(posedge clk) begin
    if (!rst_n) begin
        scl_filtered_stage2 <= 1'b1;
        sda_filtered_stage2 <= 1'b1;
        scl_prev_stage2 <= 1'b1;
        sda_prev_stage2 <= 1'b1;
        scl_rising_stage2 <= 1'b0;
        scl_falling_stage2 <= 1'b0;
        sda_rising_stage2 <= 1'b0;
        sda_falling_stage2 <= 1'b0;
        valid_stage2 <= 1'b0;
    end else if (valid_stage1) begin
        scl_filtered_stage2 <= scl_filtered_stage1;
        sda_filtered_stage2 <= sda_filtered_stage1;
        scl_prev_stage2 <= scl_filtered_stage2;
        sda_prev_stage2 <= sda_filtered_stage2;
        
        // 边沿检测
        scl_rising_stage2 <= !scl_prev_stage2 && scl_filtered_stage1;
        scl_falling_stage2 <= scl_prev_stage2 && !scl_filtered_stage1;
        sda_rising_stage2 <= !sda_prev_stage2 && sda_filtered_stage1;
        sda_falling_stage2 <= sda_prev_stage2 && !sda_filtered_stage1;
        
        valid_stage2 <= valid_stage1;
    end
end

// 并行前缀减法器的实现
// 生成借位生成和传播信号
assign borrow_generate = ~minuend & subtrahend;
assign borrow_propagate = ~minuend | subtrahend;

// 并行前缀计算借位链
assign borrow_chain[0] = borrow_generate[0];
assign borrow_chain[1] = borrow_generate[1] | (borrow_propagate[1] & borrow_chain[0]);
assign borrow_chain[2] = borrow_generate[2] | (borrow_propagate[2] & borrow_chain[1]);
assign borrow_chain[3] = borrow_generate[3] | (borrow_propagate[3] & borrow_chain[2]);
assign borrow_chain[4] = borrow_generate[4] | (borrow_propagate[4] & borrow_chain[3]);
assign borrow_chain[5] = borrow_generate[5] | (borrow_propagate[5] & borrow_chain[4]);
assign borrow_chain[6] = borrow_generate[6] | (borrow_propagate[6] & borrow_chain[5]);
assign borrow_chain[7] = borrow_generate[7] | (borrow_propagate[7] & borrow_chain[6]);

// 计算差值
assign difference[0] = minuend[0] ^ subtrahend[0];
assign difference[7:1] = minuend[7:1] ^ subtrahend[7:1] ^ borrow_chain[6:0];

// 流水线阶段3：状态处理
always @(posedge clk) begin
    if (!rst_n) begin
        scl_filtered_stage3 <= 1'b1;
        sda_filtered_stage3 <= 1'b1;
        shift_reg_stage3 <= 8'h00;
        bit_cnt_stage3 <= 3'b0;
        addr_match_stage3 <= 1'b0;
        valid_stage3 <= 1'b0;
        start_detected_stage3 <= 1'b0;
        stop_detected_stage3 <= 1'b0;
        state_stage3 <= IDLE;
        minuend <= 8'h00;
        subtrahend <= 8'h00;
    end else if (valid_stage2) begin
        scl_filtered_stage3 <= scl_filtered_stage2;
        sda_filtered_stage3 <= sda_filtered_stage2;
        valid_stage3 <= valid_stage2;
        
        // START条件检测: SCL高时SDA从高到低
        if (scl_filtered_stage2 && sda_falling_stage2) begin
            start_detected_stage3 <= 1'b1;
            stop_detected_stage3 <= 1'b0;
            state_stage3 <= START;
            bit_cnt_stage3 <= 3'b0;
            addr_match_stage3 <= 1'b0;
        end
        // STOP条件检测: SCL高时SDA从低到高
        else if (scl_filtered_stage2 && sda_rising_stage2) begin
            stop_detected_stage3 <= 1'b1;
            start_detected_stage3 <= 1'b0;
            state_stage3 <= IDLE;
        end
        // 数据采样：在SCL上升沿采样SDA
        else if (scl_rising_stage2) begin
            case (state_stage3)
                START: begin
                    state_stage3 <= ADDR;
                    shift_reg_stage3 <= {shift_reg_stage3[6:0], sda_filtered_stage2};
                    bit_cnt_stage3 <= bit_cnt_stage3 + 1'b1;
                end
                
                ADDR: begin
                    shift_reg_stage3 <= {shift_reg_stage3[6:0], sda_filtered_stage2};
                    bit_cnt_stage3 <= bit_cnt_stage3 + 1'b1;
                    
                    if (bit_cnt_stage3 == 3'b111) begin
                        state_stage3 <= ACK_ADDR;
                        // 使用并行前缀减法器检查地址匹配
                        minuend <= {1'b0, shift_reg_stage3[7:1]};
                        subtrahend <= {1'b0, slave_addr};
                        // 检查地址匹配结果通过差值判断
                        addr_match_stage3 <= (difference == 8'h00);
                    end
                end
                
                ACK_ADDR: begin
                    if (addr_match_stage3) begin
                        state_stage3 <= shift_reg_stage3[0] ? READ : WRITE;
                        bit_cnt_stage3 <= 3'b0;
                    end else begin
                        state_stage3 <= IDLE;
                    end
                end
                
                WRITE: begin
                    shift_reg_stage3 <= {shift_reg_stage3[6:0], sda_filtered_stage2};
                    bit_cnt_stage3 <= bit_cnt_stage3 + 1'b1;
                    
                    if (bit_cnt_stage3 == 3'b111) begin
                        state_stage3 <= ACK_WRITE;
                    end
                end
                
                ACK_WRITE: begin
                    state_stage3 <= WRITE;
                    bit_cnt_stage3 <= 3'b0;
                end
                
                READ: begin
                    bit_cnt_stage3 <= bit_cnt_stage3 + 1'b1;
                    
                    if (bit_cnt_stage3 == 3'b111) begin
                        state_stage3 <= ACK_READ;
                    end
                end
                
                ACK_READ: begin
                    if (!sda_filtered_stage2) begin // 主机发送ACK
                        state_stage3 <= READ;
                        bit_cnt_stage3 <= 3'b0;
                    end else begin // 主机发送NACK
                        state_stage3 <= IDLE;
                    end
                end
                
                default: state_stage3 <= IDLE;
            endcase
        end
    end
end

// 流水线阶段4：数据处理和输出
always @(posedge clk) begin
    if (!rst_n) begin
        shift_reg_stage4 <= 8'h00;
        bit_cnt_stage4 <= 3'b0;
        addr_match_stage4 <= 1'b0;
        valid_stage4 <= 1'b0;
        state_stage4 <= IDLE;
        data_out <= 8'h00;
        data_valid <= 1'b0;
        sda_out_en <= 1'b0;
        sda_out_val <= 1'b1;
    end else if (valid_stage3) begin
        shift_reg_stage4 <= shift_reg_stage3;
        bit_cnt_stage4 <= bit_cnt_stage3;
        addr_match_stage4 <= addr_match_stage3;
        valid_stage4 <= valid_stage3;
        state_stage4 <= state_stage3;
        
        // 默认不驱动SDA线
        sda_out_en <= 1'b0;
        sda_out_val <= 1'b1;
        data_valid <= 1'b0;
        
        case (state_stage4)
            ACK_ADDR: begin
                if (addr_match_stage4 && scl_filtered_stage3 == 1'b0) begin
                    // 在ACK时拉低SDA以确认地址匹配
                    sda_out_en <= 1'b1;
                    sda_out_val <= 1'b0;
                end
            end
            
            ACK_WRITE: begin
                if (addr_match_stage4 && scl_filtered_stage3 == 1'b0) begin
                    // 在ACK时拉低SDA以确认接收数据
                    sda_out_en <= 1'b1;
                    sda_out_val <= 1'b0;
                    
                    // 输出接收到的数据
                    data_out <= shift_reg_stage4;
                    data_valid <= 1'b1;
                end
            end
            
            READ: begin
                if (addr_match_stage4) begin
                    // 在读取周期驱动SDA线
                    sda_out_en <= 1'b1;
                    sda_out_val <= data_in[7-bit_cnt_stage4];
                end
            end
            
            default: begin
                sda_out_en <= 1'b0;
                data_valid <= 1'b0;
            end
        endcase
    end
end

endmodule