//SystemVerilog
module Timer_FSM_Control (
    input wire clk,
    input wire rst,
    // AXI-Stream slave interface
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    input wire [7:0] s_axis_tdata,
    // AXI-Stream master interface
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tlast
);
    // 状态编码
    localparam IDLE = 2'b00;
    localparam COUNTING = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [7:0] cnt, next_cnt;
    
    // 查找表辅助减法实现
    reg [7:0] sub_lut [0:255];
    reg [7:0] decrement_value;
    
    // 查找表初始化
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            sub_lut[i] = i - 8'd1;
        end
        decrement_value = 8'd1;
    end
    
    // 状态寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            cnt <= 8'h00;
            s_axis_tready <= 1'b1;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 8'h00;
            m_axis_tlast <= 1'b0;
        end else begin
            state <= next_state;
            cnt <= next_cnt;
            
            // AXI-Stream 接口控制
            case (next_state)
                IDLE: begin
                    s_axis_tready <= 1'b1;
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                end
                COUNTING: begin
                    s_axis_tready <= 1'b0;
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                end
                DONE: begin
                    s_axis_tready <= 1'b0;
                    m_axis_tvalid <= 1'b1;
                    m_axis_tdata <= 8'hFF; // 完成信号
                    m_axis_tlast <= 1'b1;
                end
            endcase
        end
    end
    
    // 组合逻辑 - 下一状态和输出逻辑
    always @(*) begin
        // 默认值保持当前状态
        next_state = state;
        next_cnt = cnt;
        
        case(state)
            IDLE: begin
                if (s_axis_tvalid && s_axis_tready) begin
                    next_state = COUNTING;
                    next_cnt = 8'd100; // 使用固定值或从tdata获取
                end
            end
            
            COUNTING: begin
                // 使用查找表进行递减操作
                next_cnt = sub_lut[cnt];
                
                // 状态转移逻辑
                if (cnt == 8'd1) begin
                    next_state = DONE;
                end
            end
            
            DONE: begin
                if (m_axis_tready && m_axis_tvalid) begin
                    next_state = IDLE;
                    next_cnt = 8'h00;
                end
            end
            
            default: begin
                next_state = IDLE;
                next_cnt = 8'h00;
            end
        endcase
    end
endmodule