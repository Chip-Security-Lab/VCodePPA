//SystemVerilog
module basic_rom_with_multiplier (
    input [3:0] addr,
    input [7:0] multiplicand,
    input [7:0] multiplier,
    input clk,
    input rst_n,
    input start,
    output reg [7:0] rom_data,
    output reg [15:0] product,
    output reg done
);
    // ROM部分 - 使用参数化ROM以提高可配置性
    reg [7:0] rom [0:15];
    
    initial begin
        rom[0] = 8'h12;
        rom[1] = 8'h34;
        rom[2] = 8'h56;
        rom[3] = 8'h78;
        rom[4] = 8'h9A;
        rom[5] = 8'hBC;
        rom[6] = 8'hDE;
        rom[7] = 8'hF0;
        rom[8] = 8'h00;
        rom[9] = 8'h00;
        rom[10] = 8'h00;
        rom[11] = 8'h00;
        rom[12] = 8'h00;
        rom[13] = 8'h00;
        rom[14] = 8'h00;
        rom[15] = 8'h00;
    end
    
    always @(*) begin
        rom_data = rom[addr];
    end

    // Booth乘法器部分
    booth_multiplier_8bit booth_mult (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .product(product),
        .done(done)
    );
endmodule

module booth_multiplier_8bit (
    input clk,
    input rst_n,
    input start,
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output reg [15:0] product,
    output reg done
);
    // 状态定义 - 使用单热编码提高状态机效率
    localparam IDLE = 3'b001;
    localparam CALC = 3'b010;
    localparam DONE = 3'b100;
    
    reg [2:0] state, next_state;
    reg [7:0] M; // 被乘数
    reg [3:0] count; // 迭代计数器
    reg [16:0] P; // 部分积 [product, Q, Q_1]
    
    // 状态转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 优化的下一状态逻辑 - 使用优先级判断减少复杂条件
    always @(*) begin
        next_state = IDLE; // 默认状态
        
        case (1'b1) // 优先级编码
            state[0]: next_state = start ? CALC : IDLE;
            state[1]: next_state = (count == 4'd8) ? DONE : CALC;
            state[2]: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 优化的数据处理逻辑 - 并行化处理
    reg [7:0] add_result, sub_result;
    reg [16:0] shift_result;
    reg add_sel, sub_sel;
    
    always @(*) begin
        // 预计算加法和减法结果
        add_result = P[16:9] + M;
        sub_result = P[16:9] - M;
        
        // 比较逻辑优化 - 使用并行计算
        add_sel = (P[1:0] == 2'b01);
        sub_sel = (P[1:0] == 2'b10);
        
        // 预计算右移结果
        if (add_sel)
            shift_result = {add_result, P[8:1]};
        else if (sub_sel)
            shift_result = {sub_result, P[8:1]};
        else
            shift_result = {P[16:9], P[8:1]};
            
        // 算术右移
        shift_result = {shift_result[16], shift_result[16:1]};
    end
    
    // 寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            M <= 8'b0;
            P <= 17'b0;
            count <= 4'b0;
            done <= 1'b0;
            product <= 16'b0;
        end
        else begin
            case (1'b1) // 单热编码状态机
                state[0]: begin // IDLE
                    if (start) begin
                        M <= multiplicand;
                        P <= {8'b0, multiplier, 1'b0}; // [8位部分积, 8位乘数, 1位Q_-1]
                        count <= 4'b0;
                        done <= 1'b0;
                    end
                end
                
                state[1]: begin // CALC
                    P <= shift_result;
                    count <= count + 1'b1;
                end
                
                state[2]: begin // DONE
                    product <= P[16:1]; // 最终结果
                    done <= 1'b1;
                end
            endcase
        end
    end
endmodule