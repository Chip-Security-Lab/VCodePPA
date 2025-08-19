//SystemVerilog
module mem_mapped_decoder(
    input [7:0] addr,
    input [1:0] bank_sel,
    output reg [3:0] chip_sel,
    // 新增乘法器端口
    input clk,
    input reset_n,
    input [7:0] multiplicand,
    input [7:0] multiplier,
    input mult_start,
    output reg [15:0] product,
    output reg mult_done
);
    wire addr_in_range;
    
    // 使用单个比较操作来判断地址范围
    assign addr_in_range = ~addr[7];  // addr < 8'h80 等价于 addr[7] == 0
    
    always @(*) begin
        chip_sel = 4'b0000;
        if (addr_in_range)
            chip_sel[bank_sel] = 1'b1;
    end
    
    // Booth乘法器实现
    booth_multiplier booth_mult_inst(
        .clk(clk),
        .reset_n(reset_n),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .start(mult_start),
        .product(product),
        .done(mult_done)
    );
endmodule

// Booth乘法器模块
module booth_multiplier(
    input clk,
    input reset_n,
    input [7:0] multiplicand,
    input [7:0] multiplier,
    input start,
    output reg [15:0] product,
    output reg done
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [3:0] bit_count;
    reg [7:0] mcand_reg;
    reg [16:0] partial_product; // [16:9]为部分积, [8:1]为乘数, [0]为扩展位
    reg prev_bit;
    
    // 状态机逻辑
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = CALC;
            CALC: if (bit_count == 4'd8) next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 数据路径
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            bit_count <= 4'd0;
            mcand_reg <= 8'd0;
            partial_product <= 17'd0;
            prev_bit <= 1'b0;
            product <= 16'd0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        bit_count <= 4'd0;
                        mcand_reg <= multiplicand;
                        partial_product <= {8'd0, multiplier, 1'b0}; // 初始化部分积和扩展位
                        prev_bit <= 1'b0;
                        done <= 1'b0;
                    end
                end
                
                CALC: begin
                    bit_count <= bit_count + 4'd1;
                    
                    // Booth编码: 检查当前bit和前一个bit
                    case ({partial_product[1], partial_product[0]})
                        2'b01: partial_product[16:9] <= partial_product[16:9] + mcand_reg; // +A
                        2'b10: partial_product[16:9] <= partial_product[16:9] - mcand_reg; // -A
                        default: ; // 00或11: 不做任何操作
                    endcase
                    
                    // 算术右移一位
                    partial_product <= {partial_product[16], partial_product[16:1]};
                end
                
                DONE: begin
                    product <= partial_product[16:1]; // 最终结果
                    done <= 1'b1;
                end
            endcase
        end
    end
endmodule