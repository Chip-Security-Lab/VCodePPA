//SystemVerilog
module usb_async_receiver(
    input wire dm,
    input wire dp,
    input wire fast_clk,
    input wire reset,
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg rx_error
);
    // 定义状态编码
    localparam IDLE = 2'b00, SYNC = 2'b01, DATA = 2'b10, EOP = 2'b11;
    
    // 流水线阶段1 - 输入采样和状态检测
    reg [1:0] state_stage1;
    reg [2:0] bit_count_stage1;
    reg dp_stage1, dm_stage1;
    reg [7:0] shift_reg_stage1;
    reg valid_stage1;
    
    // 流水线阶段2 - 数据处理
    reg [1:0] state_stage2;
    reg [2:0] bit_count_stage2;
    reg [7:0] shift_reg_stage2;
    reg valid_stage2;
    reg [7:0] data_stage2;
    
    // 流水线阶段3 - 输出生成
    reg [1:0] state_stage3;
    reg valid_stage3;
    reg [7:0] data_stage3;
    
    // 阶段1: 输入采样和状态检测
    always @(posedge fast_clk or posedge reset) begin
        if (reset) begin
            state_stage1 <= IDLE;
            bit_count_stage1 <= 3'h0;
            dp_stage1 <= 1'b0;
            dm_stage1 <= 1'b0;
            shift_reg_stage1 <= 8'h0;
            valid_stage1 <= 1'b0;
        end else begin
            // 采样输入信号
            dp_stage1 <= dp;
            dm_stage1 <= dm;
            
            case (state_stage1)
                IDLE: begin
                    valid_stage1 <= 1'b0;
                    if (dp && !dm) begin
                        state_stage1 <= SYNC;
                        bit_count_stage1 <= 3'h0;
                    end
                end
                
                SYNC: begin
                    if (bit_count_stage1 == 3'h7) begin
                        state_stage1 <= DATA;
                        bit_count_stage1 <= 3'h0;
                    end else begin
                        bit_count_stage1 <= bit_count_stage1 + 1'b1;
                    end
                end
                
                DATA: begin
                    shift_reg_stage1 <= {dp_stage1, shift_reg_stage1[7:1]};
                    
                    if (bit_count_stage1 == 3'h7) begin
                        state_stage1 <= EOP;
                        bit_count_stage1 <= 3'h0;
                        valid_stage1 <= 1'b1;
                    end else begin
                        bit_count_stage1 <= bit_count_stage1 + 1'b1;
                    end
                end
                
                EOP: begin
                    valid_stage1 <= 1'b0;
                    if (!dp_stage1 && !dm_stage1) begin
                        state_stage1 <= IDLE;
                    end
                end
                
                default: begin
                    state_stage1 <= IDLE;
                    bit_count_stage1 <= 3'h0;
                    valid_stage1 <= 1'b0;
                end
            endcase
        end
    end
    
    // 阶段2: 数据处理
    always @(posedge fast_clk or posedge reset) begin
        if (reset) begin
            state_stage2 <= IDLE;
            bit_count_stage2 <= 3'h0;
            shift_reg_stage2 <= 8'h0;
            valid_stage2 <= 1'b0;
            data_stage2 <= 8'h0;
        end else begin
            state_stage2 <= state_stage1;
            bit_count_stage2 <= bit_count_stage1;
            shift_reg_stage2 <= shift_reg_stage1;
            
            if (state_stage1 == DATA && bit_count_stage1 == 3'h7) begin
                data_stage2 <= {dp_stage1, shift_reg_stage1[7:1]};
                valid_stage2 <= 1'b1;
            end else if (state_stage1 == EOP && valid_stage1) begin
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 阶段3: 输出生成
    always @(posedge fast_clk or posedge reset) begin
        if (reset) begin
            state_stage3 <= IDLE;
            valid_stage3 <= 1'b0;
            data_stage3 <= 8'h0;
            rx_valid <= 1'b0;
            rx_data <= 8'h0;
            rx_error <= 1'b0;
        end else begin
            state_stage3 <= state_stage2;
            valid_stage3 <= valid_stage2;
            data_stage3 <= data_stage2;
            
            // 输出控制
            rx_valid <= valid_stage3;
            
            if (valid_stage3) begin
                rx_data <= data_stage3;
            end
            
            // 错误检测 - 简化处理
            rx_error <= (state_stage3 == EOP && !(dp_stage1 && dm_stage1)) ? 1'b0 : 
                       ((state_stage3 != IDLE && state_stage3 != SYNC && state_stage3 != DATA && state_stage3 != EOP) ? 1'b1 : rx_error);
        end
    end
    
endmodule