//SystemVerilog
module eth_mdio_interface (
    input wire clk,
    input wire reset,
    // Host interface
    input wire [4:0] phy_addr,
    input wire [4:0] reg_addr,
    input wire [15:0] write_data,
    output reg [15:0] read_data,
    input wire read_req,
    input wire write_req,
    output reg ready,
    output reg error,
    // MDIO interface
    output reg mdio_clk,
    inout wire mdio_data
);
    // 状态定义 - 使用独热编码以优化状态机实现
    localparam IDLE     = 8'b00000001;
    localparam START    = 8'b00000010;
    localparam OP       = 8'b00000100;
    localparam PHY_ADDR = 8'b00001000;
    localparam REG_ADDR = 8'b00010000;
    localparam TA       = 8'b00100000;
    localparam DATA     = 8'b01000000;
    localparam DONE     = 8'b10000000;
    
    reg [7:0] state, next_state;
    reg [5:0] bit_count, next_bit_count;
    reg [31:0] shift_reg, next_shift_reg;
    reg mdio_out, next_mdio_out;
    reg mdio_oe, next_mdio_oe;
    reg next_ready, next_error;
    reg [15:0] next_read_data;
    reg next_mdio_clk;
    
    // MDIO是双向信号
    assign mdio_data = mdio_oe ? mdio_out : 1'bz;
    
    // 优化的MDIO时钟生成 - 预先计算边沿检测
    reg mdio_clk_div, next_mdio_clk_div;
    wire mdio_clk_edge = mdio_clk_div != next_mdio_clk_div;
    wire mdio_rising_edge = mdio_clk_edge && next_mdio_clk_div;
    wire mdio_falling_edge = mdio_clk_edge && !next_mdio_clk_div;
    
    // 时钟分频逻辑
    always @(posedge clk or posedge reset) begin
        if (reset)
            mdio_clk_div <= 1'b0;
        else
            mdio_clk_div <= ~mdio_clk_div;
    end
    
    // 优化的状态转换和数据处理
    always @(*) begin
        // 默认保持当前状态
        next_state = state;
        next_bit_count = bit_count;
        next_shift_reg = shift_reg;
        next_mdio_out = mdio_out;
        next_mdio_oe = mdio_oe;
        next_ready = ready;
        next_error = error;
        next_read_data = read_data;
        next_mdio_clk = mdio_clk;
        next_mdio_clk_div = ~mdio_clk_div;
        
        // 只在MDIO时钟边沿更新状态 - 优化条件判断
        if (mdio_clk_div) begin
            case (1'b1) // 使用独热编码的case语句优化
                state[0]: begin // IDLE
                    next_mdio_clk = 1'b1;
                    next_mdio_oe = 1'b0;
                    
                    if (read_req || write_req) begin
                        // 合并读写请求处理减少逻辑重复
                        next_shift_reg = {32'hFFFFFFFF, 
                                         2'b01, 
                                         read_req ? 2'b10 : 2'b01, 
                                         phy_addr, 
                                         reg_addr, 
                                         read_req ? 2'b00 : 2'b10, 
                                         read_req ? 16'h0000 : write_data};
                        next_state = START;
                        next_bit_count = 6'd0;
                        next_ready = 1'b0;
                        next_error = 1'b0;
                        next_mdio_oe = 1'b1;
                    end
                end
                
                state[1]: begin // START
                    // 发送前导码（32位1）
                    next_mdio_out = 1'b1;
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // 只在MDIO上升沿改变状态
                        // 优化比较逻辑
                        if (bit_count >= 31) begin
                            next_state = OP;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                state[2]: begin // OP
                    // 发送起始位(01)和操作码(01=写，10=读)
                    next_mdio_out = shift_reg[31-bit_count];
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // MDIO上升沿
                        // 使用范围比较减少逻辑层次
                        if (bit_count >= 3) begin
                            next_state = PHY_ADDR;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                state[3]: begin // PHY_ADDR
                    // 发送PHY地址（5位）
                    next_mdio_out = shift_reg[27-bit_count];
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // MDIO上升沿
                        if (bit_count >= 4) begin
                            next_state = REG_ADDR;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                state[4]: begin // REG_ADDR
                    // 发送寄存器地址（5位）
                    next_mdio_out = shift_reg[22-bit_count];
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // MDIO上升沿
                        if (bit_count >= 4) begin
                            next_state = TA;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                state[5]: begin // TA
                    // 周转时间（2位：写操作为10，读操作为Z0）
                    // 优化条件判断结构
                    next_mdio_out = shift_reg[17-bit_count];
                    if (read_req && bit_count == 1)
                        next_mdio_oe = 1'b0; // 读操作释放总线
                        
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // MDIO上升沿
                        if (bit_count >= 1) begin
                            next_state = DATA;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                state[6]: begin // DATA
                    // 优化写/读数据处理逻辑
                    // 写操作时输出数据位
                    if (write_req)
                        next_mdio_out = shift_reg[15-bit_count];
                    
                    next_mdio_clk = ~mdio_clk;
                    
                    // 读数据时在MDIO下降沿采样
                    if (!write_req && mdio_clk == 1'b1)
                        next_read_data[15-bit_count] = mdio_data;
                    
                    // 状态转换逻辑优化
                    if (mdio_clk == 1'b0) begin // 只在MDIO上升沿改变状态
                        if (bit_count >= 15) begin
                            next_state = DONE;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                state[7]: begin // DONE
                    // 简化完成状态处理
                    next_mdio_clk = 1'b1;
                    next_mdio_oe = 1'b0;
                    next_ready = 1'b1;
                    next_state = IDLE;
                end
                
                default: next_state = IDLE;
            endcase
        end
    end
    
    // 时序逻辑 - 寄存器更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 6'd0;
            mdio_clk <= 1'b1;
            mdio_out <= 1'b1;
            mdio_oe <= 1'b0;
            ready <= 1'b1;
            error <= 1'b0;
            read_data <= 16'd0;
            shift_reg <= 32'd0;
        end else begin
            state <= next_state;
            bit_count <= next_bit_count;
            mdio_clk <= next_mdio_clk;
            mdio_out <= next_mdio_out;
            mdio_oe <= next_mdio_oe;
            ready <= next_ready;
            error <= next_error;
            read_data <= next_read_data;
            shift_reg <= next_shift_reg;
        end
    end
endmodule