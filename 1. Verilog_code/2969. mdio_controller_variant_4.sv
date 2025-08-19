//SystemVerilog
module mdio_controller #(
    parameter PHY_ADDR = 5'h01,
    parameter CLK_DIV = 64
)(
    input clk,
    input rst,
    input [4:0] reg_addr,
    input [15:0] data_in,
    input write_en,
    output reg [15:0] data_out,
    output reg mdio_done,
    inout mdio,
    output mdc
);
    // 状态编码
    localparam IDLE = 2'b00;
    localparam ACTIVE = 2'b01;
    localparam COMPLETE = 2'b10;
    
    // 时钟分频和计数器
    reg [$clog2(CLK_DIV)-1:0] clk_counter;
    reg [1:0] state, next_state;
    reg [5:0] bit_count; // 增加位宽以避免溢出
    reg [31:0] shift_reg;
    
    // MDIO输出控制
    reg mdio_oe;
    reg mdio_out;
    
    // 寄存输入信号
    reg [4:0] reg_addr_r;
    reg [15:0] data_in_r;
    reg write_en_r;
    
    // MDC时钟生成 - 使用位操作代替算术
    assign mdc = clk_counter[$clog2(CLK_DIV/2)];
    
    // MDIO三态输出控制
    assign mdio = mdio_oe ? mdio_out : 1'bz;
    
    // 时钟计数器逻辑 - 独立出来以优化时序
    always @(posedge clk or posedge rst) begin
        if (rst)
            clk_counter <= 0;
        else
            clk_counter <= (clk_counter == CLK_DIV-1) ? 0 : clk_counter + 1;
    end
    
    // 输入寄存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_addr_r <= 5'b0;
            data_in_r <= 16'b0;
            write_en_r <= 1'b0;
        end else begin
            reg_addr_r <= reg_addr;
            data_in_r <= data_in;
            write_en_r <= write_en;
        end
    end
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: 
                if (write_en_r)
                    next_state = ACTIVE;
            
            ACTIVE:
                if (clk_counter == CLK_DIV-1 && bit_count == 32)
                    next_state = COMPLETE;
                    
            COMPLETE:
                if (!write_en_r)
                    next_state = IDLE;
                    
            default:
                next_state = IDLE;
        endcase
    end
    
    // 状态和控制寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            bit_count <= 0;
            mdio_oe <= 0;
            mdio_done <= 0;
            shift_reg <= 32'b0;
            data_out <= 16'b0;
        end else begin
            state <= next_state;
            
            // MDIO输出始终来自移位寄存器MSB
            mdio_out <= shift_reg[31];
            
            case (state)
                IDLE: begin
                    bit_count <= 0;
                    mdio_done <= 0;
                    if (next_state == ACTIVE) begin
                        mdio_oe <= 1;
                        shift_reg <= {2'b01, PHY_ADDR, reg_addr_r, 2'b10, data_in_r};
                    end
                end
                
                ACTIVE: begin
                    if (clk_counter == CLK_DIV-1) begin
                        if (bit_count < 32) begin
                            shift_reg <= {shift_reg[30:0], (mdio_oe ? 1'b0 : mdio)};
                            bit_count <= bit_count + 1;
                        end
                    end
                end
                
                COMPLETE: begin
                    data_out <= shift_reg[15:0];
                    mdio_done <= 1;
                    mdio_oe <= 0;
                end
            endcase
        end
    end
endmodule