module subtractor_4bit_axi_stream (
    input clk,
    input reset,
    
    // AXI-Stream Slave Interface (Input)
    input [3:0] s_axis_tdata,
    input s_axis_tvalid,
    output reg s_axis_tready,
    
    // AXI-Stream Master Interface (Output)
    output reg [3:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input m_axis_tready,
    output reg m_axis_tlast
);

    // 流水线寄存器
    reg [3:0] a_stage1, b_stage1;
    reg [3:0] a_stage2, b_stage2;
    reg [3:0] diff_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 状态机状态
    localparam IDLE = 2'b00;
    localparam WAIT_B = 2'b01;
    localparam PROCESS = 2'b10;
    localparam OUTPUT = 2'b11;
    
    reg [1:0] state, next_state;
    reg [3:0] a_reg, b_reg;
    reg data_ready;
    
    // 状态机
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (s_axis_tvalid && s_axis_tready) begin
                    next_state = WAIT_B;
                end
            end
            
            WAIT_B: begin
                if (s_axis_tvalid && s_axis_tready) begin
                    next_state = PROCESS;
                end
            end
            
            PROCESS: begin
                next_state = OUTPUT;
            end
            
            OUTPUT: begin
                if (m_axis_tvalid && m_axis_tready) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 数据路径和控制逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // 复位所有流水线寄存器
            a_stage1 <= 4'b0;
            b_stage1 <= 4'b0;
            a_stage2 <= 4'b0;
            b_stage2 <= 4'b0;
            diff_stage3 <= 4'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            
            // 复位AXI-Stream接口信号
            s_axis_tready <= 1'b0;
            m_axis_tdata <= 4'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            
            // 复位内部寄存器
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            data_ready <= 1'b0;
        end else begin
            // 默认值
            s_axis_tready <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            
            case (state)
                IDLE: begin
                    s_axis_tready <= 1'b1;
                    if (s_axis_tvalid && s_axis_tready) begin
                        a_reg <= s_axis_tdata;
                    end
                end
                
                WAIT_B: begin
                    s_axis_tready <= 1'b1;
                    if (s_axis_tvalid && s_axis_tready) begin
                        b_reg <= s_axis_tdata;
                    end
                end
                
                PROCESS: begin
                    // 第一阶段：输入寄存
                    a_stage1 <= a_reg;
                    b_stage1 <= b_reg;
                    valid_stage1 <= 1'b1;
                    
                    // 第二阶段：数据传递
                    a_stage2 <= a_stage1;
                    b_stage2 <= b_stage1;
                    valid_stage2 <= valid_stage1;
                    
                    // 第三阶段：执行减法
                    diff_stage3 <= a_stage2 - b_stage2;
                    valid_stage3 <= valid_stage2;
                    
                    data_ready <= 1'b1;
                end
                
                OUTPUT: begin
                    m_axis_tvalid <= 1'b1;
                    m_axis_tdata <= diff_stage3;
                    m_axis_tlast <= 1'b1;
                    
                    if (m_axis_tvalid && m_axis_tready) begin
                        data_ready <= 1'b0;
                    end
                end
                
                default: begin
                    // 保持默认值
                end
            endcase
        end
    end
endmodule