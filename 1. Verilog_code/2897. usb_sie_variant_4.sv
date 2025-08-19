//SystemVerilog
module usb_sie_axis (
    input wire clk,
    input wire reset_n,
    
    // AXI-Stream Slave Interface
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream Master Interface
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg m_axis_tlast,
    
    // Status signals
    output reg [2:0] state
);
    
    // 增加流水线深度：从4级状态扩展到8级状态
    localparam IDLE = 3'b000, 
               RX_READY = 3'b001, 
               RX_CAPTURE = 3'b010, 
               PROC_START = 3'b011, 
               PROC_MID = 3'b100,
               PROC_END = 3'b101, 
               TX_START = 3'b110, 
               TX_COMPLETE = 3'b111;
    
    // 预寄存输入数据，实现前向寄存器重定时
    reg [7:0] s_axis_tdata_reg;
    reg s_axis_tvalid_reg;
    
    // 流水线寄存器
    reg [7:0] buffer_stage1;
    reg [7:0] buffer_stage2;
    reg [7:0] buffer_stage3;
    
    // 控制信号流水线
    reg packet_end_stage1;
    reg packet_end_stage2;
    reg packet_end_stage3;
    
    // 状态寄存器的下一个状态
    reg [2:0] next_state;
    
    // 输入数据预寄存
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            s_axis_tdata_reg <= 8'h00;
            s_axis_tvalid_reg <= 1'b0;
        end else begin
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tvalid_reg <= s_axis_tvalid;
        end
    end
    
    // 状态机组合逻辑部分
    always @(*) begin
        next_state = state; // 默认保持当前状态
        
        case (state)
            IDLE: begin
                if (s_axis_tvalid_reg)
                    next_state = RX_READY;
            end
            
            RX_READY: begin
                if (s_axis_tvalid_reg)
                    next_state = RX_CAPTURE;
            end
            
            RX_CAPTURE: begin
                next_state = PROC_START;
            end
            
            PROC_START: begin
                next_state = PROC_MID;
            end
            
            PROC_MID: begin
                next_state = PROC_END;
            end
            
            PROC_END: begin
                next_state = TX_START;
            end
            
            TX_START: begin
                if (m_axis_tready)
                    next_state = TX_COMPLETE;
            end
            
            TX_COMPLETE: begin
                if (m_axis_tready && m_axis_tvalid)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // tready信号生成逻辑
    assign s_axis_tready = (state == RX_READY || state == RX_CAPTURE);
    
    // 流水线控制逻辑
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 8'h00;
            m_axis_tlast <= 1'b0;
            
            // 重置流水线寄存器
            buffer_stage1 <= 8'h00;
            buffer_stage2 <= 8'h00;
            buffer_stage3 <= 8'h00;
            
            // 重置控制信号
            packet_end_stage1 <= 1'b0;
            packet_end_stage2 <= 1'b0;
            packet_end_stage3 <= 1'b0;
        end else begin
            // 状态更新
            state <= next_state;
            
            // 数据流处理
            case (state)
                IDLE: begin
                    m_axis_tlast <= 1'b0;
                end
                
                RX_CAPTURE: begin
                    // 第一级流水线：采集寄存的数据
                    buffer_stage1 <= s_axis_tdata_reg;
                    packet_end_stage1 <= (s_axis_tdata_reg == 8'hFF); // 示例终止条件
                end
                
                PROC_START: begin
                    // 处理开始级 - 前向推移寄存器
                    buffer_stage2 <= buffer_stage1;
                    packet_end_stage2 <= packet_end_stage1;
                end
                
                PROC_MID: begin
                    // 处理中间级
                    buffer_stage3 <= buffer_stage2;
                    packet_end_stage3 <= packet_end_stage2;
                end
                
                PROC_END: begin
                    // 处理结束级 - 准备数据输出
                    m_axis_tdata <= buffer_stage3;
                    m_axis_tlast <= packet_end_stage3;
                    m_axis_tvalid <= 1'b1;
                end
                
                TX_COMPLETE: begin
                    // 完成传输级
                    if (m_axis_tready && m_axis_tvalid) begin
                        m_axis_tvalid <= 1'b0;
                    end
                end
                
                default: begin
                    // 保持当前值
                end
            endcase
        end
    end
endmodule