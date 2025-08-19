//SystemVerilog
module eth_mii_decoder (
    input wire rx_clk,
    input wire rst_n,
    input wire rx_dv,
    input wire rx_er,
    input wire [3:0] rxd,
    output reg [7:0] data_out,
    output reg data_valid,
    output reg error,
    output reg sfd_detected,
    output reg carrier_sense
);
    // 状态编码优化为单热码(one-hot)，减少状态转换逻辑复杂度
    localparam [3:0] IDLE     = 4'b0001,
                     PREAMBLE = 4'b0010,
                     SFD      = 4'b0100,
                     DATA     = 4'b1000;
    
    // 流水线阶段1: 状态检测与转换
    reg [3:0] state_stage1, next_state_stage1;
    reg [3:0] rxd_stage1, prev_rxd_stage1;
    reg rx_dv_stage1, rx_er_stage1;
    reg load_upper_nibble_stage1;
    reg valid_stage1;

    // 流水线阶段2: 数据处理
    reg [3:0] state_stage2, rxd_stage2, prev_rxd_stage2;
    reg rx_dv_stage2, rx_er_stage2, load_upper_nibble_stage2;
    reg valid_stage2;
    reg sfd_detected_stage2;
    
    // 流水线阶段3: 输出生成
    reg [7:0] data_out_stage3;
    reg data_valid_stage3;
    reg error_stage3;
    reg sfd_detected_stage3;
    reg carrier_sense_stage3;
    
    // 阶段1: 状态转换逻辑，组合逻辑部分
    always @(*) begin
        next_state_stage1 = IDLE;
        load_upper_nibble_stage1 = 1'b0;
        
        if (rx_dv) begin
            case (state_stage1)
                IDLE: begin
                    next_state_stage1 = (rxd == 4'h5) ? PREAMBLE : IDLE;
                end
                
                PREAMBLE: begin
                    if (rxd == 4'h5)
                        next_state_stage1 = PREAMBLE;
                    else if (rxd == 4'hD)
                        next_state_stage1 = SFD;
                    else
                        next_state_stage1 = IDLE;
                end
                
                SFD: begin
                    if (prev_rxd_stage1 == 4'hD && rxd == 4'h5) begin
                        next_state_stage1 = DATA;
                    end else
                        next_state_stage1 = IDLE;
                end
                
                DATA: begin
                    next_state_stage1 = DATA;
                    load_upper_nibble_stage1 = 1'b1;
                end
                
                default: next_state_stage1 = IDLE;
            endcase
        end
    end

    // 阶段1寄存器更新: 捕获输入和计算下一状态
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            prev_rxd_stage1 <= 4'h0;
            rxd_stage1 <= 4'h0;
            rx_dv_stage1 <= 1'b0;
            rx_er_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            // 更新状态和存储当前输入
            state_stage1 <= next_state_stage1;
            prev_rxd_stage1 <= rxd;
            rxd_stage1 <= rxd;
            rx_dv_stage1 <= rx_dv;
            rx_er_stage1 <= rx_er;
            valid_stage1 <= 1'b1;  // 指示阶段1有效数据
            
            // 当rx_dv为低时重置状态
            if (!rx_dv) begin
                state_stage1 <= IDLE;
                valid_stage1 <= 1'b0;
            end
        end
    end

    // 阶段2寄存器更新: 处理状态转换结果
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            rxd_stage2 <= 4'h0;
            prev_rxd_stage2 <= 4'h0;
            rx_dv_stage2 <= 1'b0;
            rx_er_stage2 <= 1'b0;
            load_upper_nibble_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            sfd_detected_stage2 <= 1'b0;
        end else begin
            // 传递阶段1的数据到阶段2
            state_stage2 <= state_stage1;
            rxd_stage2 <= rxd_stage1;
            prev_rxd_stage2 <= prev_rxd_stage1;
            rx_dv_stage2 <= rx_dv_stage1;
            rx_er_stage2 <= rx_er_stage1;
            load_upper_nibble_stage2 <= load_upper_nibble_stage1;
            valid_stage2 <= valid_stage1;
            
            // 检测SFD并设置标志
            sfd_detected_stage2 <= 1'b0;
            if (valid_stage1 && rx_dv_stage1 && 
                state_stage1 == DATA && state_stage2 == SFD) begin
                sfd_detected_stage2 <= 1'b1;
            end
        end
    end

    // 阶段3寄存器更新: 生成最终输出
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage3 <= 8'h00;
            data_valid_stage3 <= 1'b0;
            error_stage3 <= 1'b0;
            sfd_detected_stage3 <= 1'b0;
            carrier_sense_stage3 <= 1'b0;
        end else begin
            // 默认值设置
            data_valid_stage3 <= 1'b0;
            error_stage3 <= rx_er_stage2;
            carrier_sense_stage3 <= rx_dv_stage2;
            sfd_detected_stage3 <= sfd_detected_stage2;
            
            // 数据处理逻辑
            if (valid_stage2 && rx_dv_stage2) begin
                if (state_stage2 == DATA) begin
                    if (sfd_detected_stage2) begin
                        data_out_stage3[3:0] <= rxd_stage2;
                    end else if (load_upper_nibble_stage2) begin
                        data_out_stage3[7:4] <= rxd_stage2;
                        data_out_stage3[3:0] <= prev_rxd_stage2;
                        data_valid_stage3 <= 1'b1;
                    end
                end
            end
        end
    end
    
    // 输出赋值
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h00;
            data_valid <= 1'b0;
            error <= 1'b0;
            sfd_detected <= 1'b0;
            carrier_sense <= 1'b0;
        end else begin
            data_out <= data_out_stage3;
            data_valid <= data_valid_stage3;
            error <= error_stage3;
            sfd_detected <= sfd_detected_stage3;
            carrier_sense <= carrier_sense_stage3;
        end
    end
endmodule