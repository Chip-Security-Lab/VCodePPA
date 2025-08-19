//SystemVerilog
module AsyncResetOR(
    input  logic        aclk,
    input  logic        aresetn,
    
    // 输入AXI-Stream接口
    input  logic [3:0]  s_axis_d1_tdata,
    input  logic [3:0]  s_axis_d2_tdata,
    input  logic        s_axis_tvalid,
    output logic        s_axis_tready,
    
    // 输出AXI-Stream接口
    output logic [7:0]  m_axis_tdata,
    output logic        m_axis_tvalid,
    input  logic        m_axis_tready,
    output logic        m_axis_tlast
);
    // 内部信号
    logic [7:0] mult_result;
    logic [7:0] accumulator;
    logic [3:0] multiplier_reg;
    logic [7:0] multiplicand_reg;
    logic [2:0] i_count;
    
    // 状态机定义
    typedef enum logic [1:0] {
        IDLE,
        COMPUTE,
        OUTPUT_DATA
    } state_t;
    
    state_t current_state, next_state;
    
    // 状态转换逻辑
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            current_state <= IDLE;
            i_count <= 0;
            accumulator <= 8'b0;
            multiplier_reg <= 4'b0;
            multiplicand_reg <= 8'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tdata <= 8'hFF;
        end else begin
            case (current_state)
                IDLE: begin
                    m_axis_tvalid <= 1'b0;
                    if (s_axis_tvalid && s_axis_tready) begin
                        // 初始化计算
                        accumulator <= 8'b0;
                        multiplier_reg <= s_axis_d1_tdata;
                        multiplicand_reg <= {4'b0, s_axis_d2_tdata};
                        i_count <= 0;
                        current_state <= COMPUTE;
                    end
                end
                
                COMPUTE: begin
                    if (multiplier_reg[0])
                        accumulator <= accumulator + multiplicand_reg;
                        
                    multiplier_reg <= multiplier_reg >> 1;
                    multiplicand_reg <= multiplicand_reg << 1;
                    
                    i_count <= i_count + 1;
                    
                    if (i_count == 3) begin
                        current_state <= OUTPUT_DATA;
                        m_axis_tdata <= accumulator;
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast <= 1'b1;
                    end
                end
                
                OUTPUT_DATA: begin
                    if (m_axis_tready && m_axis_tvalid) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                        current_state <= IDLE;
                    end
                end
                
                default: current_state <= IDLE;
            endcase
        end
    end
    
    // 输入接口握手信号控制
    assign s_axis_tready = (current_state == IDLE);
    
endmodule