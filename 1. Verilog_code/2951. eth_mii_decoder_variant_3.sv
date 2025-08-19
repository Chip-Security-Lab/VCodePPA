//SystemVerilog
module eth_mii_decoder (
    input  wire        rx_clk,
    input  wire        rst_n,
    
    // MII输入接口
    input  wire        rx_dv,
    input  wire        rx_er,
    input  wire [3:0]  rxd,
    
    // AXI-Stream输出接口
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    output wire        m_axis_tlast,
    output wire        m_axis_tuser,  // 用于传递错误信息
    input  wire        m_axis_tready,
    
    // 额外状态信号
    output wire        sfd_detected,
    output wire        carrier_sense
);

    // 状态定义
    localparam IDLE = 2'b00, PREAMBLE = 2'b01, SFD = 2'b10, DATA = 2'b11;
    
    // 第一级流水线 - 状态控制和数据采集
    reg [1:0]  state_stage1, next_state_stage1;
    reg [3:0]  rxd_stage1;
    reg [3:0]  prev_rxd_stage1;
    reg        rx_dv_stage1, rx_er_stage1;
    reg        valid_stage1;
    reg        sfd_detected_stage1;
    reg        packet_end_stage1;
    
    // 第二级流水线 - 数据处理
    reg [1:0]  state_stage2;
    reg [3:0]  rxd_stage2;
    reg [3:0]  prev_rxd_stage2;
    reg        rx_dv_stage2, rx_er_stage2; 
    reg        valid_stage2;
    reg        sfd_detected_stage2;
    reg        packet_end_stage2;
    reg [7:0]  data_stage2;
    
    // 第三级流水线 - 输出控制
    reg [7:0]  data_stage3;
    reg        valid_stage3;
    reg        error_stage3;
    reg        sfd_detected_stage3;
    reg        packet_end_stage3;
    reg        carrier_sense_stage3;
    
    // 将内部寄存器连接到AXI-Stream接口
    assign m_axis_tdata  = data_stage3;
    assign m_axis_tvalid = valid_stage3;
    assign m_axis_tlast  = packet_end_stage3;
    assign m_axis_tuser  = error_stage3;
    
    // 额外状态信号
    assign sfd_detected  = sfd_detected_stage3;
    assign carrier_sense = carrier_sense_stage3;
    
    // 流水线Stage 1: 数据采集和状态控制
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            rxd_stage1 <= 4'h0;
            prev_rxd_stage1 <= 4'h0;
            rx_dv_stage1 <= 1'b0;
            rx_er_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            sfd_detected_stage1 <= 1'b0;
            packet_end_stage1 <= 1'b0;
        end else begin
            rxd_stage1 <= rxd;
            prev_rxd_stage1 <= rxd_stage1;
            rx_dv_stage1 <= rx_dv;
            rx_er_stage1 <= rx_er;
            
            // 默认值设置
            valid_stage1 <= 1'b0;
            sfd_detected_stage1 <= 1'b0;
            packet_end_stage1 <= 1'b0;
            
            if (rx_dv) begin
                case (state_stage1)
                    IDLE: begin
                        if (rxd == 4'h5)
                            state_stage1 <= PREAMBLE;
                    end
                    
                    PREAMBLE: begin
                        if (rxd == 4'h5)
                            state_stage1 <= PREAMBLE;
                        else if (rxd == 4'hD)
                            state_stage1 <= SFD;
                        else
                            state_stage1 <= IDLE;
                    end
                    
                    SFD: begin
                        if (rxd == 4'h5 && rxd_stage1 == 4'hD) begin
                            sfd_detected_stage1 <= 1'b1;
                            state_stage1 <= DATA;
                            valid_stage1 <= 1'b1;
                        end else
                            state_stage1 <= IDLE;
                    end
                    
                    DATA: begin
                        valid_stage1 <= 1'b1;
                    end
                endcase
            end else begin
                if (state_stage1 == DATA) begin
                    packet_end_stage1 <= 1'b1;
                    valid_stage1 <= 1'b1;
                end
                state_stage1 <= IDLE;
            end
        end
    end
    
    // 流水线Stage 2: 数据处理
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            rxd_stage2 <= 4'h0;
            prev_rxd_stage2 <= 4'h0;
            rx_dv_stage2 <= 1'b0;
            rx_er_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            sfd_detected_stage2 <= 1'b0;
            packet_end_stage2 <= 1'b0;
            data_stage2 <= 8'h00;
        end else begin
            // 数据传递到第二级
            state_stage2 <= state_stage1;
            rxd_stage2 <= rxd_stage1;
            prev_rxd_stage2 <= prev_rxd_stage1;
            rx_dv_stage2 <= rx_dv_stage1;
            rx_er_stage2 <= rx_er_stage1;
            valid_stage2 <= valid_stage1;
            sfd_detected_stage2 <= sfd_detected_stage1;
            packet_end_stage2 <= packet_end_stage1;
            
            // 数据处理逻辑
            if (valid_stage1) begin
                if (state_stage1 == DATA || packet_end_stage1) begin
                    data_stage2[7:4] <= rxd_stage1;
                    data_stage2[3:0] <= prev_rxd_stage1;
                end
            end
        end
    end
    
    // 流水线Stage 3: 输出控制
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= 8'h00;
            valid_stage3 <= 1'b0;
            error_stage3 <= 1'b0;
            sfd_detected_stage3 <= 1'b0;
            packet_end_stage3 <= 1'b0;
            carrier_sense_stage3 <= 1'b0;
        end else begin
            // 反压控制 - 只有当下游准备好或当前没有有效数据时才更新
            if (m_axis_tready || !valid_stage3) begin
                data_stage3 <= data_stage2;
                valid_stage3 <= valid_stage2;
                error_stage3 <= rx_er_stage2;
                sfd_detected_stage3 <= sfd_detected_stage2;
                packet_end_stage3 <= packet_end_stage2;
                carrier_sense_stage3 <= rx_dv_stage2;
            end
        end
    end

endmodule