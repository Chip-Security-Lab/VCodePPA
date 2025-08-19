//SystemVerilog
module split_trans_bridge #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 32
) (
    input clk, rst_n,
    // Master端
    input [AWIDTH-1:0] m_addr,
    input [DWIDTH-1:0] m_wdata,
    input m_req, m_wr,
    output [DWIDTH-1:0] m_rdata,
    output m_ack,
    // Slave端
    output [AWIDTH-1:0] s_addr,
    output [DWIDTH-1:0] s_wdata,
    output s_req, s_wr,
    input [DWIDTH-1:0] s_rdata,
    input s_ack
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam REQ = 2'b01;
    localparam WAIT_ACK = 2'b10;
    localparam RESP = 2'b11;
    
    // 内部信号
    wire [1:0] state;
    wire [2:0] trans_id, current_id;
    wire [DWIDTH-1:0] resp_data_out;
    wire buffer_write_en;
    
    // 控制单元
    control_unit #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) ctrl_unit (
        .clk(clk),
        .rst_n(rst_n),
        .m_req(m_req),
        .m_wr(m_wr),
        .m_addr(m_addr),
        .m_wdata(m_wdata),
        .s_ack(s_ack),
        .s_rdata(s_rdata),
        .state(state),
        .trans_id(trans_id),
        .current_id(current_id),
        .s_addr(s_addr),
        .s_wdata(s_wdata),
        .s_req(s_req),
        .s_wr(s_wr),
        .m_ack(m_ack),
        .buffer_write_en(buffer_write_en)
    );
    
    // 响应数据缓冲模块
    response_buffer #(
        .DWIDTH(DWIDTH)
    ) resp_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(buffer_write_en),
        .write_id(current_id),
        .read_id(current_id),
        .write_data(s_rdata),
        .read_data(resp_data_out)
    );
    
    // 数据输出多路复用器
    data_mux #(
        .DWIDTH(DWIDTH)
    ) output_mux (
        .s_wr(s_wr),
        .buffer_data(resp_data_out),
        .m_rdata(m_rdata)
    );
    
endmodule

// 控制单元模块
module control_unit #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 32
) (
    input clk, rst_n,
    // Master接口信号
    input m_req, m_wr,
    input [AWIDTH-1:0] m_addr,
    input [DWIDTH-1:0] m_wdata,
    // Slave接口信号
    input s_ack,
    input [DWIDTH-1:0] s_rdata,
    // 内部状态和控制信号
    output reg [1:0] state,
    output reg [2:0] trans_id,
    output reg [2:0] current_id,
    // Slave输出信号
    output reg [AWIDTH-1:0] s_addr,
    output reg [DWIDTH-1:0] s_wdata,
    output reg s_req, s_wr,
    // Master输出信号
    output reg m_ack,
    // 缓冲区写使能
    output reg buffer_write_en
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam REQ = 2'b01;
    localparam WAIT_ACK = 2'b10;
    localparam RESP = 2'b11;
    
    // 状态机实现
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            m_ack <= 0;
            s_req <= 0;
            trans_id <= 0;
            current_id <= 0;
            s_addr <= 0;
            s_wdata <= 0;
            s_wr <= 0;
            buffer_write_en <= 0;
        end else begin
            // 默认状态
            buffer_write_en <= 0;
            
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
                        if (!s_wr) buffer_write_en <= 1;
                        state <= WAIT_ACK;
                        trans_id <= trans_id + 1;
                    end
                end
                WAIT_ACK: begin
                    m_ack <= 1;
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

// 响应数据缓冲模块
module response_buffer #(
    parameter DWIDTH = 32
) (
    input clk, rst_n,
    input write_en,
    input [2:0] write_id,
    input [2:0] read_id,
    input [DWIDTH-1:0] write_data,
    output [DWIDTH-1:0] read_data
);
    reg [DWIDTH-1:0] buffer [0:7];  // 8个事务的响应缓冲区
    
    // 初始化缓冲区 - 展开for循环
    initial begin
        buffer[0] = 0;
        buffer[1] = 0;
        buffer[2] = 0;
        buffer[3] = 0;
        buffer[4] = 0;
        buffer[5] = 0;
        buffer[6] = 0;
        buffer[7] = 0;
    end
    
    // 写入操作
    always @(posedge clk) begin
        if (write_en) buffer[write_id] <= write_data;
    end
    
    // 读取操作
    assign read_data = buffer[read_id];
endmodule

// 数据输出多路复用器
module data_mux #(
    parameter DWIDTH = 32
) (
    input s_wr,
    input [DWIDTH-1:0] buffer_data,
    output [DWIDTH-1:0] m_rdata
);
    // 写请求时，不需要返回数据;读请求时，返回缓冲区数据
    assign m_rdata = buffer_data;
endmodule