//SystemVerilog
module Comparator_FSM #(parameter WIDTH = 16) (
    input              clk,
    input              start,
    input  [WIDTH-1:0] val_m,
    input  [WIDTH-1:0] val_n,
    output reg         done,
    output reg         equal
);
    // 使用独热编码替代二进制编码
    localparam IDLE    = 4'b0001;
    localparam COMPARE = 4'b0010;
    localparam DONE    = 4'b0100;
    localparam ERROR   = 4'b1000; // 添加错误状态以保持完整性
    
    reg [3:0] curr_state;
    reg [$clog2(WIDTH)-1:0] bit_cnt;
    
    // 前向寄存器重定时：添加寄存器以捕获输入数据
    reg start_r;
    reg [WIDTH-1:0] val_m_r;
    reg [WIDTH-1:0] val_n_r;
    
    // 条件反相减法器算法所需的信号
    reg [1:0] subtract_result;
    reg borrow_in;
    wire borrow_out;
    wire [1:0] diff;
    
    // 条件反相减法器实现
    wire a = val_m_r[bit_cnt];
    wire b = val_n_r[bit_cnt];
    wire b_inv = ~b;
    wire sel = borrow_in;
    wire mux_out = sel ? b : b_inv;
    assign diff = a ^ mux_out ^ borrow_in;
    assign borrow_out = (~a & b) | (~(a ^ b) & borrow_in);
    
    // 使用条件反相减法器的比较结果
    wire bit_compare_result = (diff == 1'b0);

    // 初始化FSM状态
    initial begin
        curr_state = IDLE;
        done = 0;
        equal = 0;
        bit_cnt = 0;
        start_r = 0;
        val_m_r = 0;
        val_n_r = 0;
        borrow_in = 0;
        subtract_result = 0;
    end

    // 寄存器输入信号，减少输入到第一级寄存器的延迟
    always @(posedge clk) begin
        start_r <= start;
        val_m_r <= val_m;
        val_n_r <= val_n;
    end

    always @(posedge clk) begin
        // 默认值设置
        done <= 0;
        
        case(1'b1) // 独热编码的情况下使用case(1'b1)
            curr_state[0]: begin // IDLE
                if (start_r) begin
                    bit_cnt <= 0;
                    curr_state <= COMPARE;
                    borrow_in <= 0; // 初始化借位为0
                end
            end
            
            curr_state[1]: begin // COMPARE
                // 更新条件反相减法器的借位
                borrow_in <= borrow_out;
                
                if (!bit_compare_result) begin
                    equal <= 0;
                    curr_state <= DONE;
                end else if (bit_cnt == WIDTH-1) begin
                    equal <= 1;
                    curr_state <= DONE;
                end else begin
                    bit_cnt <= bit_cnt + 1;
                end
            end
            
            curr_state[2]: begin // DONE
                done <= 1;
                curr_state <= IDLE;
            end
            
            default: begin // ERROR或未定义状态
                curr_state <= IDLE;
            end
        endcase
    end
endmodule