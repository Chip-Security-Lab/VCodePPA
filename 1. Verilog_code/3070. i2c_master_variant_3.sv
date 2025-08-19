//SystemVerilog
module i2c_master(
    input wire clk, rst_n,
    input wire [6:0] slave_addr,
    input wire [7:0] data_in,
    input wire rw, start,
    output reg [7:0] data_out,
    output reg busy, ack_error,
    inout wire scl, sda
);
    localparam IDLE=4'd0, START=4'd1, ADDR=4'd2, ACK1=4'd3,
               WRITE=4'd4, READ=4'd5, ACK2=4'd6, STOP=4'd7;
    reg [3:0] state, next;
    reg [7:0] shift_reg;
    reg [2:0] bit_count;
    reg scl_ena, sda_out;
    reg stretch;
    
    // 流水线寄存器
    reg [2:0] bit_count_next_pipe;
    reg [2:0] g_signals_pipe;
    reg [2:0] p_signals_pipe;
    reg [3:0] carries_pipe;
    
    // 跳跃进位加法器相关信号
    wire [2:0] bit_count_next;
    wire [2:0] g_signals;
    wire [2:0] p_signals;
    wire [3:0] carries;
    
    // 生成和传播信号计算 - 第一阶段
    assign g_signals[0] = bit_count[0] & 1'b1;
    assign g_signals[1] = bit_count[1] & 1'b0;
    assign g_signals[2] = bit_count[2] & 1'b0;
    
    assign p_signals[0] = bit_count[0] | 1'b1;
    assign p_signals[1] = bit_count[1] | 1'b0;
    assign p_signals[2] = bit_count[2] | 1'b0;
    
    // 流水线寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_signals_pipe <= 3'd0;
            p_signals_pipe <= 3'd0;
            carries_pipe <= 4'd0;
            bit_count_next_pipe <= 3'd0;
        end else begin
            g_signals_pipe <= g_signals;
            p_signals_pipe <= p_signals;
            carries_pipe <= carries;
            bit_count_next_pipe <= bit_count_next;
        end
    end
    
    // 跳跃进位计算 - 第二阶段
    assign carries[0] = 1'b0;
    assign carries[1] = g_signals_pipe[0] | (p_signals_pipe[0] & carries_pipe[0]);
    assign carries[2] = g_signals_pipe[1] | (p_signals_pipe[1] & carries_pipe[1]);
    assign carries[3] = g_signals_pipe[2] | (p_signals_pipe[2] & carries_pipe[2]);
    
    // 和的计算 - 第三阶段
    assign bit_count_next[0] = bit_count[0] ^ 1'b1 ^ carries_pipe[0];
    assign bit_count_next[1] = bit_count[1] ^ 1'b0 ^ carries_pipe[1];
    assign bit_count_next[2] = bit_count[2] ^ 1'b0 ^ carries_pipe[2];
    
    assign scl = scl_ena ? 1'bz : 1'b0;
    assign sda = sda_out ? 1'bz : 1'b0;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            shift_reg <= 8'd0;
            bit_count <= 3'd0;
            scl_ena <= 1'b0;
            sda_out <= 1'b1;
            busy <= 1'b0;
            ack_error <= 1'b0;
            stretch <= 1'b0;
        end else begin
            state <= next;
            busy <= (state != IDLE);
            
            case (state)
                IDLE: if (start) shift_reg <= {slave_addr, rw};
                START: begin scl_ena <= 1'b1; sda_out <= 1'b0; end
                ADDR: begin
                    sda_out <= shift_reg[7-bit_count];
                    if (bit_count < 3'd7) bit_count <= bit_count_next_pipe;
                    else bit_count <= 3'd0;
                end
                ACK1: begin
                    sda_out <= 1'b1;
                    ack_error <= sda;
                    if (rw && !ack_error) shift_reg <= 8'd0;
                    else if (!rw) shift_reg <= data_in;
                end
                WRITE: begin
                    sda_out <= shift_reg[7-bit_count];
                    if (bit_count < 3'd7) bit_count <= bit_count_next_pipe;
                    else bit_count <= 3'd0;
                end
                READ: begin
                    sda_out <= 1'b1;
                    shift_reg <= {shift_reg[6:0], sda};
                    if (bit_count < 3'd7) bit_count <= bit_count_next_pipe;
                    else begin
                        bit_count <= 3'd0;
                        data_out <= {shift_reg[6:0], sda};
                    end
                end
                ACK2: sda_out <= rw ? 1'b1 : 1'b0;
                STOP: begin sda_out <= 1'b0; scl_ena <= 1'b0; end
            endcase
        end
    
    always @(*)
        case(state)
            IDLE: next = start ? START : IDLE;
            START: next = ADDR;
            ADDR: next = (bit_count == 3'd7) ? ACK1 : ADDR;
            ACK1: next = (ack_error) ? STOP : (rw ? READ : WRITE);
            WRITE: next = (bit_count == 3'd7) ? ACK2 : WRITE;
            READ: next = (bit_count == 3'd7) ? ACK2 : READ;
            ACK2: next = STOP;
            STOP: next = IDLE;
            default: next = IDLE;
        endcase
endmodule