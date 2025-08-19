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
    // 状态编码 - 使用单热编码以提高性能和降低功耗
    localparam [3:0] IDLE = 4'b0001, START = 4'b0010, ADDR = 4'b0100, RW = 4'b1000;
    localparam [3:0] ACK1 = 4'b0011, DATA = 4'b0110, ACK2 = 4'b1100, STOP = 4'b1001;
    
    reg [3:0] state, next;
    reg [2:0] bit_cnt; // 优化位宽，只需3位即可表示0-7
    reg [7:0] shift_reg;
    reg sda_out, sda_oe;
    reg scl_enable;
    reg [6:0] clk_div_count; // 优化位宽，100需要7位
    
    // SDA三态控制
    assign sda = sda_oe ? sda_out : 1'bz;
    
    // SCL生成的时钟分频器 - 优化比较逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            clk_div_count <= 7'h0;
            scl <= 1'b1;
        end else if (scl_enable) begin
            clk_div_count <= clk_div_count + 1'b1;
            // 使用相等比较而不是大于等于比较
            if (clk_div_count == 7'd99) begin
                scl <= ~scl;
                clk_div_count <= 7'h0;
            end
        end else begin
            scl <= 1'b1;
            clk_div_count <= 7'h0;
        end
    end
    
    // 状态寄存器 - 优化条件检查
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= IDLE;
            bit_cnt <= 3'h0;
            shift_reg <= 8'h0;
            busy <= 1'b0;
            done <= 1'b0;
            rd_data <= 8'h0;
            sda_oe <= 1'b1;
            sda_out <= 1'b1;
            scl_enable <= 1'b0;
        end else begin
            state <= next;
            
            case (state)
                IDLE: begin
                    bit_cnt <= 3'h0;
                    done <= 1'b0;
                    sda_oe <= 1'b1;
                    sda_out <= 1'b1;
                    if (start_xfer) begin
                        busy <= 1'b1;
                        shift_reg <= {addr, rw};
                    end
                end
                
                START: begin
                    scl_enable <= 1'b1;
                    sda_out <= 1'b0; // 添加START条件
                end
                
                ADDR: begin
                    // 仅在SCL低电平和特定计数值时进行操作
                    if (!scl && clk_div_count == 7'd10) begin
                        if (bit_cnt < 3'h7) begin
                            sda_out <= shift_reg[7];
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                end
                
                RW: begin
                    if (!scl && clk_div_count == 7'd10) begin
                        sda_out <= rw;
                        bit_cnt <= 3'h0;
                    end
                end
                
                ACK1: begin
                    if (!scl && clk_div_count == 7'd10) begin
                        sda_oe <= 1'b0;  // 释放SDA以供从机ACK
                        // 根据读写模式准备数据
                        shift_reg <= rw ? 8'h0 : wr_data;
                    end else if (scl && clk_div_count == 7'd50) begin
                        // 使用单一比较操作
                        if (sda != 1'b0) begin
                            next <= STOP; // NACK，直接转到STOP
                        end
                    end
                end
                
                DATA: begin
                    if (!scl && clk_div_count == 7'd10) begin
                        if (rw) begin
                            // 读模式
                            sda_oe <= 1'b0;
                        end else begin
                            // 写模式
                            sda_oe <= 1'b1;
                            sda_out <= shift_reg[7];
                            shift_reg <= {shift_reg[6:0], 1'b0};
                        end
                        // 位计数检查优化 - 使用等于比较
                        bit_cnt <= (bit_cnt == 3'h7) ? 3'h0 : bit_cnt + 1'b1;
                    end else if (rw && scl && clk_div_count == 7'd50) begin
                        // 采样读取数据
                        shift_reg <= {shift_reg[6:0], sda};
                    end
                end
                
                ACK2: begin
                    if (!scl && clk_div_count == 7'd10) begin
                        if (rw) begin
                            // 主机ACK
                            sda_oe <= 1'b1;
                            sda_out <= 1'b0;
                            rd_data <= shift_reg;
                        end else begin
                            // 从机ACK
                            sda_oe <= 1'b0;
                        end
                    end
                end
                
                STOP: begin
                    // 简化STOP条件检查
                    if (scl && clk_div_count == 7'd50) begin
                        sda_oe <= 1'b1;
                        sda_out <= 1'b0;
                    end else if (scl && clk_div_count == 7'd80) begin
                        sda_out <= 1'b1;
                        busy <= 1'b0;
                        done <= 1'b1;
                        scl_enable <= 1'b0;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // 优化状态转换逻辑 - 使用边沿检测而不是电平检测
    always @(*) begin
        // 默认保持当前状态
        next = state;
        
        case (state)
            IDLE: begin
                if (start_xfer) next = START;
            end
            
            START: begin
                next = ADDR;
            end
            
            ADDR: begin
                // 优化条件检查 - 使用等于比较
                if (bit_cnt == 3'h7 && scl) next = RW;
            end
            
            RW: begin
                if (scl) next = ACK1;
            end
            
            ACK1: begin
                // 简化条件比较
                if (scl && clk_div_count == 7'd90 && sda == 1'b0) next = DATA;
            end
            
            DATA: begin
                // 使用更高效的范围比较
                if (bit_cnt == 3'h0 && scl && clk_div_count == 7'd90) next = ACK2;
            end
            
            ACK2: begin
                if (scl && clk_div_count == 7'd90) next = STOP;
            end
            
            STOP: begin
                // 更精确的状态转换条件
                if (scl && clk_div_count == 7'd99) next = IDLE;
            end
            
            default: begin
                next = IDLE;
            end
        endcase
    end
    
endmodule