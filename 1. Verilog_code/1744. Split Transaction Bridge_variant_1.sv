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
    // 定义状态常量 - 使用单热码编码以提高稳定性
    localparam IDLE     = 4'b0001;
    localparam REQ      = 4'b0010;
    localparam WAIT_ACK = 4'b0100;
    localparam RESP     = 4'b1000;
    
    reg [3:0] state, next_state;
    reg [2:0] trans_id, current_id;
    reg [DWIDTH-1:0] resp_data [0:7];  // 8个事务的响应缓冲区
    
    // 条件反相减法器相关信号
    wire [3:0] addend_a, addend_b;
    wire [3:0] sub_result;
    wire subtract_mode;
    reg [3:0] c_in;
    wire [3:0] xor_b;
    wire [3:0] sum;
    
    // 条件反相减法器逻辑
    assign addend_a = {1'b0, trans_id};  // 扩展到4位
    assign addend_b = 4'b0001;           // 增量值1
    assign subtract_mode = 1'b0;         // 0表示加法，1表示减法
    
    // 根据减法模式条件反相B输入
    assign xor_b = addend_b ^ {4{subtract_mode}};
    
    // 生成适当的进位输入
    always @(*) begin
        c_in[0] = subtract_mode;
        c_in[1] = (addend_a[0] & xor_b[0]) | (c_in[0] & (addend_a[0] | xor_b[0]));
        c_in[2] = (addend_a[1] & xor_b[1]) | (c_in[1] & (addend_a[1] | xor_b[1]));
        c_in[3] = (addend_a[2] & xor_b[2]) | (c_in[2] & (addend_a[2] | xor_b[2]));
    end
    
    // 计算和
    assign sum[0] = addend_a[0] ^ xor_b[0] ^ c_in[0];
    assign sum[1] = addend_a[1] ^ xor_b[1] ^ c_in[1];
    assign sum[2] = addend_a[2] ^ xor_b[2] ^ c_in[2];
    assign sum[3] = addend_a[3] ^ xor_b[3] ^ c_in[3];
    
    // 最终结果
    assign sub_result = sum;
    
    // 初始化存储器块使用always块而非initial块
    always @(posedge clk or negedge rst_n) begin
        integer i;
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                resp_data[i] <= 0;
            end
        end
    end
    
    // 状态转移逻辑优化 - 分为组合逻辑和时序逻辑
    always @(*) begin
        // 默认状态保持不变
        next_state = state;
        
        case (1'b1) // 单热码状态机的优势
            state[0]: begin // IDLE
                if (m_req) next_state = REQ;
            end
            
            state[1]: begin // REQ
                if (s_req && s_ack) next_state = WAIT_ACK;
            end
            
            state[2]: begin // WAIT_ACK
                next_state = RESP;
            end
            
            state[3]: begin // RESP
                if (!m_req || (m_req && m_ack)) next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 控制信号和数据路径逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_ack <= 1'b0;
            s_req <= 1'b0;
            trans_id <= 3'b0;
            current_id <= 3'b0;
            m_rdata <= {DWIDTH{1'b0}};
            s_addr <= {AWIDTH{1'b0}};
            s_wdata <= {DWIDTH{1'b0}};
            s_wr <= 1'b0;
        end else begin
            case (1'b1)
                state[0]: begin // IDLE
                    if (m_req) begin
                        s_addr <= m_addr;
                        s_wr <= m_wr;
                        if (m_wr) s_wdata <= m_wdata;
                        s_req <= 1'b1;
                        current_id <= trans_id;
                    end
                end
                
                state[1]: begin // REQ
                    if (s_req && s_ack) begin
                        s_req <= 1'b0;
                        // 使用条件赋值而非if条件块来减少门级延迟
                        resp_data[current_id] <= s_wr ? resp_data[current_id] : s_rdata;
                        // 使用条件反相减法器的结果进行事务ID递增
                        trans_id <= sub_result[2:0];
                    end
                end
                
                state[2]: begin // WAIT_ACK
                    m_ack <= 1'b1;
                    // 使用条件选择器优化
                    m_rdata <= s_wr ? m_rdata : resp_data[current_id];
                end
                
                state[3]: begin // RESP
                    if (!m_req || (m_req && m_ack)) begin
                        m_ack <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule