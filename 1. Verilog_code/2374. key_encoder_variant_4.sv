//SystemVerilog
module key_encoder (
    // 时钟和复位信号
    input wire aclk,
    input wire aresetn,
    
    // 输入AXI-Stream接口
    input wire [15:0] s_axis_tdata,
    input wire s_axis_tvalid,
    input wire s_axis_tlast,
    output wire s_axis_tready,
    
    // 输出AXI-Stream接口
    output wire [3:0] m_axis_tdata,
    output wire m_axis_tvalid,
    output wire m_axis_tlast,
    input wire m_axis_tready
);

    // 内部寄存器和线网
    reg [3:0] encoded_data;
    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;
    reg [3:0] m_axis_tdata_reg;
    reg m_axis_tlast_reg;
    
    // 状态机状态定义
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam WAITING = 2'b10;
    reg [1:0] state, next_state;
    
    // 状态机逻辑
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
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
                if (s_axis_tvalid)
                    next_state = PROCESSING;
            end
            
            PROCESSING: begin
                if (m_axis_tready)
                    next_state = s_axis_tvalid ? PROCESSING : IDLE;
                else
                    next_state = WAITING;
            end
            
            WAITING: begin
                if (m_axis_tready)
                    next_state = s_axis_tvalid ? PROCESSING : IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 优化的编码逻辑：使用优先编码器
    always @(*) begin
        casez(s_axis_tdata)
            16'b1???????????????: encoded_data = 4'hF;
            16'b01??????????????: encoded_data = 4'hE;
            16'b001?????????????: encoded_data = 4'hD;
            16'b0001????????????: encoded_data = 4'hC;
            16'b00001???????????: encoded_data = 4'hB;
            16'b000001??????????: encoded_data = 4'hA;
            16'b0000001?????????: encoded_data = 4'h9;
            16'b00000001????????: encoded_data = 4'h8;
            16'b000000001???????: encoded_data = 4'h7;
            16'b0000000001??????: encoded_data = 4'h6;
            16'b00000000001?????: encoded_data = 4'h5;
            16'b000000000001????: encoded_data = 4'h4;
            16'b0000000000001???: encoded_data = 4'h3;
            16'b00000000000001??: encoded_data = 4'h2;
            16'b000000000000001?: encoded_data = 4'h1;
            16'b0000000000000001: encoded_data = 4'h0;
            default: encoded_data = 4'h0;
        endcase
    end
    
    // AXI-Stream 控制逻辑
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axis_tready_reg <= 1'b0;
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tdata_reg <= 4'h0;
            m_axis_tlast_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    s_axis_tready_reg <= 1'b1;
                    m_axis_tvalid_reg <= 1'b0;
                end
                
                PROCESSING: begin
                    if (s_axis_tvalid && s_axis_tready_reg) begin
                        m_axis_tdata_reg <= encoded_data;
                        m_axis_tvalid_reg <= 1'b1;
                        m_axis_tlast_reg <= s_axis_tlast;
                        s_axis_tready_reg <= m_axis_tready;
                    end
                end
                
                WAITING: begin
                    s_axis_tready_reg <= 1'b0;
                    if (m_axis_tready) begin
                        m_axis_tvalid_reg <= 1'b0;
                        s_axis_tready_reg <= 1'b1;
                    end
                end
                
                default: begin
                    s_axis_tready_reg <= 1'b1;
                    m_axis_tvalid_reg <= 1'b0;
                end
            endcase
        end
    end
    
    // 输出赋值
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;

endmodule