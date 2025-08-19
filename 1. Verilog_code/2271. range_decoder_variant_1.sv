//SystemVerilog
module range_decoder(
    input [7:0] addr,
    output reg rom_sel,
    output reg ram_sel,
    output reg io_sel,
    output reg error
);
    always @(*) begin
        // 默认情况下所有选择信号为0
        {rom_sel, ram_sel, io_sel, error} = 4'b0000;
        
        // 使用更高效的并行范围检测而非级联的if-else
        // ROM: 0x00-0x3F
        rom_sel = (addr < 8'h40);
        
        // RAM: 0x40-0xBF
        ram_sel = (addr >= 8'h40) && (addr < 8'hC0);
        
        // IO: 0xC0-0xFE
        io_sel = (addr >= 8'hC0) && (addr < 8'hFF);
        
        // ERROR: 0xFF
        error = (addr == 8'hFF);
    end
endmodule

module shift_add_multiplier(
    input clk,
    input rst_n,
    input start,
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output reg [15:0] product,
    output reg done
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam FINISH = 2'b10;
    
    reg [1:0] state, next_state;
    reg [7:0] mcand_reg;
    reg [7:0] mplier_reg;
    reg [15:0] acc_reg;
    reg [3:0] bit_count;
    
    // 状态转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = start ? CALC : IDLE;
            CALC: next_state = (bit_count == 4'd8) ? FINISH : CALC;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 数据处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mcand_reg <= 8'h0;
            mplier_reg <= 8'h0;
            acc_reg <= 16'h0;
            product <= 16'h0;
            bit_count <= 4'h0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        mcand_reg <= multiplicand;
                        mplier_reg <= multiplier;
                        acc_reg <= 16'h0;
                        bit_count <= 4'h0;
                        done <= 1'b0;
                    end
                end
                
                CALC: begin
                    // 如果当前位为1，则累加
                    if (mplier_reg[0]) begin
                        acc_reg <= acc_reg + {8'h0, mcand_reg};
                    end
                    // 乘数右移，被乘数左移
                    mplier_reg <= mplier_reg >> 1;
                    mcand_reg <= mcand_reg << 1;
                    bit_count <= bit_count + 4'h1;
                end
                
                FINISH: begin
                    product <= acc_reg;
                    done <= 1'b1;
                end
            endcase
        end
    end
endmodule