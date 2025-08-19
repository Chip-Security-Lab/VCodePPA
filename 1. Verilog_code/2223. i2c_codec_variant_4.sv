//SystemVerilog
module i2c_codec (
    input wire clk, rstn, 
    input wire start_xfer, rw,
    input wire [6:0] addr,
    input wire [7:0] wr_data,
    inout wire sda,
    output reg scl,
    output reg [7:0] rd_data,
    output reg busy, done
);
    // 状态定义 - 使用独热编码减少状态解码逻辑深度
    localparam [7:0] IDLE  = 8'b00000001,
                     START = 8'b00000010,
                     ADDR  = 8'b00000100,
                     RW    = 8'b00001000,
                     ACK1  = 8'b00010000,
                     DATA  = 8'b00100000,
                     ACK2  = 8'b01000000,
                     STOP  = 8'b10000000;
                     
    reg [7:0] state, next;
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;
    reg sda_out, sda_oe;
    reg scl_en;
    reg [7:0] addr_rw;
    
    // 提前计算下一位值和移位结果，减少DATA状态的关键路径
    reg [7:0] next_shift_reg;
    wire next_sda_bit = shift_reg[7];
    wire [3:0] next_bit_cnt = bit_cnt + 1'b1;
    wire bit_done = (bit_cnt == 4'd7);
    
    // SDA三态控制
    assign sda = sda_oe ? sda_out : 1'bz;
    
    // 状态转换逻辑 - 拆分为并行结构减少组合逻辑深度
    always @(*) begin
        next = IDLE; // 默认值
        
        if (state[0]) begin // IDLE
            next = start_xfer ? START : IDLE;
        end
        
        if (state[1]) begin // START
            next = ADDR;
        end
        
        if (state[2]) begin // ADDR
            next = bit_done ? RW : ADDR;
        end
        
        if (state[3]) begin // RW
            next = ACK1;
        end
        
        if (state[4]) begin // ACK1
            next = DATA;
        end
        
        if (state[5]) begin // DATA
            next = bit_done ? ACK2 : DATA;
        end
        
        if (state[6]) begin // ACK2
            next = STOP;
        end
        
        if (state[7]) begin // STOP
            next = IDLE;
        end
    end
    
    // 提前计算下一个移位寄存器值，减少关键路径
    always @(*) begin
        if (state[5] && rw) begin // DATA状态读操作
            next_shift_reg = {shift_reg[6:0], sda};
        end else if ((state[2] || (state[5] && !rw)) && !scl) begin // ADDR状态或DATA写操作
            next_shift_reg = {shift_reg[6:0], 1'b0};
        end else if (state[4] && scl) begin // ACK1状态结束
            next_shift_reg = rw ? 8'h00 : wr_data;
        end else begin
            next_shift_reg = shift_reg;
        end
    end
    
    // 寄存器更新和状态机实现
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin 
            state <= IDLE; 
            bit_cnt <= 0; 
            scl <= 1'b1;
            busy <= 1'b0;
            done <= 1'b0;
            rd_data <= 8'h00;
            sda_out <= 1'b1;
            sda_oe <= 1'b1;
            shift_reg <= 8'h00;
            scl_en <= 1'b0;
        end else begin
            state <= next;
            
            // SCL生成逻辑 - 减少条件判断链
            if (state[0] || state[1] || state[7]) begin // IDLE, START, STOP
                scl <= 1'b1;
            end else if (scl_en) begin
                scl <= ~scl;
            end
            
            // 根据当前状态执行操作
            case (1'b1) // 独热编码状态的并行判断
                state[0]: begin // IDLE
                    sda_out <= 1'b1;
                    sda_oe <= 1'b1;
                    done <= 1'b0;
                    busy <= start_xfer ? 1'b1 : 1'b0;
                    if (start_xfer) begin
                        addr_rw <= {addr, rw};
                    end
                    bit_cnt <= 0;
                    scl_en <= 1'b0;
                end
                
                state[1]: begin // START
                    sda_out <= 1'b0;
                    sda_oe <= 1'b1;
                    bit_cnt <= 0;
                    shift_reg <= {addr, rw};
                    scl_en <= 1'b0;
                end
                
                state[2]: begin // ADDR
                    scl_en <= 1'b1;
                    sda_oe <= 1'b1;
                    sda_out <= next_sda_bit;
                    
                    if (scl && bit_cnt < 7) begin
                        bit_cnt <= next_bit_cnt;
                        shift_reg <= next_shift_reg;
                    end
                end
                
                state[3]: begin // RW
                    scl_en <= 1'b1;
                    sda_oe <= 1'b1;
                    sda_out <= rw;
                    
                    if (scl) begin
                        bit_cnt <= 0;
                    end
                end
                
                state[4]: begin // ACK1
                    sda_oe <= 1'b0;
                    scl_en <= 1'b1;
                    
                    if (scl) begin
                        shift_reg <= next_shift_reg;
                    end
                end
                
                state[5]: begin // DATA
                    scl_en <= 1'b1;
                    
                    if (rw) begin // 读操作
                        sda_oe <= 1'b0;
                        if (scl && bit_cnt < 7) begin
                            shift_reg <= next_shift_reg;
                            bit_cnt <= next_bit_cnt;
                        end
                    end else begin // 写操作
                        sda_oe <= 1'b1;
                        sda_out <= next_sda_bit;
                        if (scl && bit_cnt < 7) begin
                            bit_cnt <= next_bit_cnt;
                            shift_reg <= next_shift_reg;
                        end
                    end
                end
                
                state[6]: begin // ACK2
                    scl_en <= 1'b1;
                    
                    if (rw) begin // 读操作完成
                        rd_data <= shift_reg;
                        sda_oe <= 1'b1;
                        sda_out <= 1'b0; // Master ACK
                    end else begin // 写操作完成
                        sda_oe <= 1'b0; // Release SDA for slave ACK
                    end
                end
                
                state[7]: begin // STOP
                    sda_oe <= 1'b1;
                    scl_en <= 1'b0;
                    
                    if (!scl) begin
                        sda_out <= 1'b0;
                    end else begin
                        sda_out <= 1'b1;
                        done <= 1'b1;
                        busy <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule