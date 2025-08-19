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
    parameter IDLE = 2'b00;
    parameter REQ = 2'b01;
    parameter WAIT_ACK = 2'b10;
    parameter RESP = 2'b11;
    
    // 状态寄存器
    reg [1:0] state, state_next;
    reg [2:0] trans_id, trans_id_next;
    reg [2:0] current_id, current_id_next;
    
    // 响应数据缓冲器
    reg [DWIDTH-1:0] resp_data [0:7];
    reg [DWIDTH-1:0] resp_data_next [0:7];
    
    // 控制信号缓冲器
    reg m_ack_next;
    reg s_req_next;
    reg [AWIDTH-1:0] s_addr_next;
    reg [DWIDTH-1:0] s_wdata_next;
    reg s_wr_next;
    reg [DWIDTH-1:0] m_rdata_next;
    
    // 初始化响应数据缓冲区
    integer i;
    initial begin
        for (i = 0; i < 8; i = i + 1) resp_data[i] = 0;
    end
    
    // 组合逻辑部分
    always @(*) begin
        state_next = state;
        trans_id_next = trans_id;
        current_id_next = current_id;
        m_ack_next = m_ack;
        s_req_next = s_req;
        s_addr_next = s_addr;
        s_wdata_next = s_wdata;
        s_wr_next = s_wr;
        m_rdata_next = m_rdata;
        
        for (i = 0; i < 8; i = i + 1) begin
            resp_data_next[i] = resp_data[i];
        end
        
        case (state)
            IDLE: begin
                if (m_req) begin
                    s_addr_next = m_addr;
                    s_wr_next = m_wr;
                    if (m_wr) s_wdata_next = m_wdata;
                    s_req_next = 1;
                    state_next = REQ;
                    current_id_next = trans_id;
                end
            end
            REQ: begin
                if (s_req && s_ack) begin
                    s_req_next = 0;
                    if (!s_wr) resp_data_next[current_id] = s_rdata;
                    state_next = WAIT_ACK;
                    trans_id_next = trans_id + 1;
                end
            end
            WAIT_ACK: begin
                m_ack_next = 1;
                if (!s_wr) m_rdata_next = resp_data[current_id];
                state_next = RESP;
            end
            RESP: begin
                if (!m_req || (m_req && m_ack)) begin
                    m_ack_next = 0;
                    state_next = IDLE;
                end
            end
            default: state_next = IDLE;
        endcase
    end
    
    // 时序逻辑部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            m_ack <= 0;
            s_req <= 0;
            trans_id <= 0;
            current_id <= 0;
            m_rdata <= 0;
            s_addr <= 0;
            s_wdata <= 0;
            s_wr <= 0;
            for (i = 0; i < 8; i = i + 1) resp_data[i] <= 0;
        end else begin
            state <= state_next;
            trans_id <= trans_id_next;
            current_id <= current_id_next;
            m_ack <= m_ack_next;
            s_req <= s_req_next;
            s_addr <= s_addr_next;
            s_wdata <= s_wdata_next;
            s_wr <= s_wr_next;
            m_rdata <= m_rdata_next;
            for (i = 0; i < 8; i = i + 1) resp_data[i] <= resp_data_next[i];
        end
    end
endmodule