//SystemVerilog
// 顶层模块
module multi_parity_checker (
    input [1:0] mode,  // 00: no, 01: even, 10: odd, 11: invert
    input [7:0] data,
    input [7:0] multiplier,
    input [7:0] multiplicand,
    input clk,
    input rst_n,
    output [7:0] product,
    output [1:0] parity
);
    // 内部连线
    wire even_parity;
    wire odd_parity;
    wire [7:0] mult_result;
    
    // 子模块实例化
    shift_add_multiplier mult_unit (
        .clk(clk),
        .rst_n(rst_n),
        .multiplier(multiplier),
        .multiplicand(multiplicand),
        .product(mult_result)
    );
    
    parity_calculator parity_calc (
        .data(data),
        .even_parity(even_parity),
        .odd_parity(odd_parity)
    );
    
    parity_selector parity_sel (
        .mode(mode),
        .even_parity(even_parity),
        .odd_parity(odd_parity),
        .parity(parity)
    );
    
    assign product = mult_result;
    
endmodule

// 移位累加乘法器模块
module shift_add_multiplier (
    input clk,
    input rst_n,
    input [7:0] multiplier,
    input [7:0] multiplicand,
    output reg [7:0] product
);
    // 内部寄存器
    reg [3:0] bit_counter;
    reg [7:0] shift_multiplicand;
    reg [7:0] temp_product;
    reg [7:0] shift_multiplier;
    
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // 状态转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = CALC;
            CALC: next_state = (bit_counter == 4'd8) ? DONE : CALC;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 数据处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 4'd0;
            shift_multiplicand <= 8'd0;
            temp_product <= 8'd0;
            shift_multiplier <= 8'd0;
            product <= 8'd0;
        end
        else begin
            case (state)
                IDLE: begin
                    bit_counter <= 4'd0;
                    shift_multiplicand <= multiplicand;
                    temp_product <= 8'd0;
                    shift_multiplier <= multiplier;
                end
                
                CALC: begin
                    if (shift_multiplier[0]) begin
                        temp_product <= temp_product + shift_multiplicand;
                    end
                    shift_multiplicand <= shift_multiplicand << 1;
                    shift_multiplier <= shift_multiplier >> 1;
                    bit_counter <= bit_counter + 4'd1;
                end
                
                DONE: begin
                    product <= temp_product;
                end
            endcase
        end
    end
    
endmodule

// 奇偶校验计算子模块
module parity_calculator (
    input [7:0] data,
    output even_parity,
    output odd_parity
);
    // 参数化设计，提高可复用性
    assign even_parity = ~^data;  // 偶校验
    assign odd_parity = ^data;    // 奇校验
    
endmodule

// 奇偶校验选择子模块
module parity_selector (
    input [1:0] mode,
    input even_parity,
    input odd_parity,
    output reg [1:0] parity
);
    // 模式选择逻辑
    always @(*) begin
        case (mode)
            2'b00: parity = 2'b00;             // 无校验
            2'b01: parity = {even_parity, 1'b0}; // 偶校验
            2'b10: parity = {odd_parity, 1'b1};  // 奇校验
            2'b11: parity = {~odd_parity, 1'b1}; // 反转奇校验
        endcase
    end
    
endmodule