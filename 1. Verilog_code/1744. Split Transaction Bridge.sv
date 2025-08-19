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
    reg [1:0] state;
    reg [2:0] trans_id, current_id;
    reg [DWIDTH-1:0] resp_data [0:7];  // 8个事务的响应缓冲区
    integer i;
    
    initial begin
        for (i = 0; i < 8; i = i + 1) resp_data[i] = 0;
    end
    
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
        end else begin
            case (state)
                IDLE: begin
                    if (m_req) begin
                        s_addr <= m_addr;
                        s_wr <= m_wr;
                        if (m_wr) s_wdata <= m_wdata;
                        s_req <= 1;
                        state <= REQ;
                        current_id <= trans_id;
                    end
                end
                REQ: begin
                    if (s_req && s_ack) begin
                        s_req <= 0;
                        if (!s_wr) resp_data[current_id] <= s_rdata;
                        state <= WAIT_ACK;
                        trans_id <= trans_id + 1;
                    end
                end
                WAIT_ACK: begin
                    m_ack <= 1;
                    if (!s_wr) m_rdata <= resp_data[current_id];
                    state <= RESP;
                end
                RESP: begin
                    if (!m_req || (m_req && m_ack)) begin
                        m_ack <= 0;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule