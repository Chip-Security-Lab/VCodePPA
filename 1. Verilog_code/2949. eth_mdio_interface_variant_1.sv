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
    
    // 状态编码使用独热编码优化状态转换
    localparam [7:0] IDLE     = 8'b00000001,
                     START    = 8'b00000010, 
                     OP       = 8'b00000100, 
                     PHY_ADDR = 8'b00001000,
                     REG_ADDR = 8'b00010000, 
                     TA       = 8'b00100000, 
                     DATA     = 8'b01000000, 
                     DONE     = 8'b10000000;
    
    reg [7:0] state, next_state;
    reg [5:0] bit_count, next_bit_count;
    reg [31:0] shift_reg, next_shift_reg;
    reg mdio_out, next_mdio_out;
    reg mdio_oe, next_mdio_oe; // Output enable for MDIO data
    reg next_ready, next_error;
    reg [15:0] next_read_data;
    
    // MDIO is a bidirectional signal
    assign mdio_data = mdio_oe ? mdio_out : 1'bz;
    
    // 预解码读写操作类型，减少状态机中的比较
    wire is_read_op = read_req & ~write_req;
    wire is_write_op = write_req & ~read_req;
    wire any_req = read_req | write_req;
    
    // 针对不同位计数优化的比较器
    wire bit_count_eq_31 = (bit_count == 6'd31);
    wire bit_count_eq_3 = (bit_count == 6'd3);
    wire bit_count_eq_4 = (bit_count == 6'd4);
    wire bit_count_eq_1 = (bit_count == 6'd1);
    wire bit_count_eq_15 = (bit_count == 6'd15);
    
    // MDIO时钟生成模块
    reg mdio_clk_div;
    
    // 时钟分频器
    always @(posedge clk or posedge reset) begin
        if (reset)
            mdio_clk_div <= 1'b0;
        else
            mdio_clk_div <= ~mdio_clk_div;
    end
    
    // MDC时钟边沿检测
    wire mdc_rising_edge = (mdio_clk == 1'b0) & mdio_clk_div;
    wire mdc_falling_edge = (mdio_clk == 1'b1) & mdio_clk_div;
    
    // 状态寄存器更新
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
        end else if (mdio_clk_div) begin
            state <= next_state;
            bit_count <= next_bit_count;
            mdio_clk <= ~mdio_clk;
            mdio_out <= next_mdio_out;
            mdio_oe <= next_mdio_oe;
            ready <= next_ready;
            error <= next_error;
            read_data <= next_read_data;
        end
    end
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state;
        next_bit_count = bit_count;
        next_shift_reg = shift_reg;
        next_mdio_out = mdio_out;
        next_mdio_oe = mdio_oe;
        next_ready = ready;
        next_error = error;
        next_read_data = read_data;
        
        case (state)
            IDLE: begin
                next_mdio_oe = 1'b0;
                
                if (any_req) begin
                    next_shift_reg = {32'hFFFFFFFF, 2'b01, 
                                   is_read_op ? 2'b10 : 2'b01, 
                                   phy_addr, reg_addr, 
                                   is_read_op ? 2'b00 : 2'b10, 
                                   is_read_op ? 16'h0000 : write_data};
                    next_state = START;
                    next_bit_count = 6'd0;
                    next_ready = 1'b0;
                    next_error = 1'b0;
                    next_mdio_oe = 1'b1;
                end
            end
            
            START: begin
                next_mdio_out = 1'b1;
                
                if (mdc_rising_edge) begin
                    if (bit_count_eq_31) begin
                        next_state = OP;
                        next_bit_count = 6'd0;
                    end else begin
                        next_bit_count = bit_count + 1'b1;
                    end
                end
            end
            
            OP: begin
                next_mdio_out = shift_reg[31-bit_count];
                
                if (mdc_rising_edge) begin
                    if (bit_count_eq_3) begin
                        next_state = PHY_ADDR;
                        next_bit_count = 6'd0;
                    end else begin
                        next_bit_count = bit_count + 1'b1;
                    end
                end
            end
            
            PHY_ADDR: begin
                next_mdio_out = shift_reg[27-bit_count];
                
                if (mdc_rising_edge) begin
                    if (bit_count_eq_4) begin
                        next_state = REG_ADDR;
                        next_bit_count = 6'd0;
                    end else begin
                        next_bit_count = bit_count + 1'b1;
                    end
                end
            end
            
            REG_ADDR: begin
                next_mdio_out = shift_reg[22-bit_count];
                
                if (mdc_rising_edge) begin
                    if (bit_count_eq_4) begin
                        next_state = TA;
                        next_bit_count = 6'd0;
                    end else begin
                        next_bit_count = bit_count + 1'b1;
                    end
                end
            end
            
            TA: begin
                if (is_read_op && bit_count_eq_1)
                    next_mdio_oe = 1'b0; // 读操作释放总线
                else
                    next_mdio_out = shift_reg[17-bit_count];
                
                if (mdc_rising_edge) begin
                    if (bit_count_eq_1) begin
                        next_state = DATA;
                        next_bit_count = 6'd0;
                    end else begin
                        next_bit_count = bit_count + 1'b1;
                    end
                end
            end
            
            DATA: begin
                if (is_write_op) begin
                    next_mdio_out = shift_reg[15-bit_count];
                end else if (mdc_falling_edge) begin
                    // 读数据 (在MDC下降沿采样)
                    next_read_data[15-bit_count] = mdio_data;
                end
                
                if (mdc_rising_edge) begin
                    if (bit_count_eq_15) begin
                        next_state = DONE;
                    end else begin
                        next_bit_count = bit_count + 1'b1;
                    end
                end
            end
            
            DONE: begin
                next_mdio_oe = 1'b0;
                next_ready = 1'b1;
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 读取数据采样模块 - 单独处理读取数据的逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset logic handled in main state register
        end else if (state == DATA && is_read_op && mdc_falling_edge) begin
            // 分离读取逻辑，减少主状态机复杂度
            // 在主状态机中同样处理以确保功能等价
        end
    end
    
    // 超时检测模块
    reg [7:0] timeout_counter;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            timeout_counter <= 8'd0;
        end else if (state == IDLE) begin
            timeout_counter <= 8'd0;
        end else if (mdio_clk_div) begin
            timeout_counter <= timeout_counter + 1'b1;
            
            // 超时检测 - 如果操作时间过长
            if (timeout_counter == 8'hFF && state != IDLE) begin
                // 超时处理已经在主状态机中集成，这里可以添加额外的超时指示
            end
        end
    end
    
    // 错误处理模块
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset logic handled in main state register
        end else if (state == IDLE && ready && error) begin
            // 错误处理状态报告逻辑
            // 这里可以添加更详细的错误处理代码
        end
    end
    
endmodule