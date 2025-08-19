//SystemVerilog
module split_trans_bridge #(parameter DWIDTH=32, AWIDTH=32) (
    input clk, rst_n,
    // Master端
    input [AWIDTH-1:0] m_addr,
    input [DWIDTH-1:0] m_wdata,
    input m_req, m_wr,
    output reg [DWIDTH-1:0] m_rdata,
    output reg m_ack,
    // Slave端
    output reg [AWIDTH-1:0] s_addr,
    output reg [DWIDTH-1:0] s_wdata,
    output reg s_req, s_wr,
    input [DWIDTH-1:0] s_rdata,
    input s_ack
);
    // 定义状态常量
    localparam IDLE = 2'b00;
    localparam REQ = 2'b01;
    localparam WAIT_ACK = 2'b10;
    localparam RESP = 2'b11;
    
    reg [1:0] state, next_state;
    reg [2:0] trans_id, current_id;
    reg [DWIDTH-1:0] resp_data [0:7];  // 8个事务的响应缓冲区

    // 初始化响应数据缓冲区
    integer i;
    initial begin
        for (i = 0; i < 8; i = i + 1) 
            resp_data[i] = 0;
    end
    
    // 状态寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (m_req) next_state = REQ;
            end
            REQ: begin
                if (s_req && s_ack) next_state = WAIT_ACK;
            end
            WAIT_ACK: begin
                next_state = RESP;
            end
            RESP: begin
                if (!m_req || (m_req && m_ack)) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // 事务ID控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trans_id <= 0;
            current_id <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (m_req) begin
                        current_id <= trans_id;
                    end
                end
                REQ: begin
                    if (s_req && s_ack) begin
                        trans_id <= trans_id + 1;
                    end
                end
            endcase
        end
    end
    
    // Slave接口控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_req <= 0;
            s_addr <= 0;
            s_wdata <= 0;
            s_wr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (m_req) begin
                        s_addr <= m_addr;
                        s_wr <= m_wr;
                        if (m_wr) s_wdata <= m_wdata;
                        s_req <= 1;
                    end
                end
                REQ: begin
                    if (s_req && s_ack) begin
                        s_req <= 0;
                    end
                end
            endcase
        end
    end
    
    // 响应数据缓存逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时不需要清空resp_data，已在initial块中初始化
        end else begin
            if (state == REQ && s_req && s_ack && !s_wr) begin
                resp_data[current_id] <= s_rdata;
            end
        end
    end
    
    // 使用条件求和减法算法实现减法器
    wire [DWIDTH-1:0] sub_result;
    wire [DWIDTH-1:0] a;
    wire [DWIDTH-1:0] b;
    assign a = m_wdata; // 假设m_wdata是被减数
    assign b = s_rdata; // 假设s_rdata是减数

    // 条件求和减法算法
    assign sub_result = a + (~b + 1'b1); // a - b = a + (~b + 1)

    // Master接口控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_ack <= 0;
            m_rdata <= 0;
        end else begin
            case (state)
                WAIT_ACK: begin
                    m_ack <= 1;
                    if (!s_wr) m_rdata <= resp_data[current_id]; // 使用缓存的数据
                end
                RESP: begin
                    if (!m_req || (m_req && m_ack)) begin
                        m_ack <= 0;
                    end
                end
            endcase
        end
    end
    
endmodule