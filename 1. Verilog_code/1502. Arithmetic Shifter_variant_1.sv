//SystemVerilog
// IEEE 1364-2005 Verilog
module arith_shifter #(parameter WIDTH = 8) (
    input wire clk, rst, shift_en,
    input wire [WIDTH-1:0] data_in,
    input wire [2:0] shift_amt,
    output reg [WIDTH-1:0] result
);

    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam SHIFT = 2'b01;
    localparam RESET = 2'b10;
    
    // 使用借位减法器借位链实现算术右移
    reg [WIDTH-1:0] shift_result;
    reg sign_bit;
    reg [WIDTH-1:0] borrow_chain;
    reg [2:0] effective_shift;
    
    always @(*) begin
        sign_bit = data_in[WIDTH-1];
        effective_shift = (shift_amt < WIDTH) ? shift_amt : 3'd7;
        
        // 初始化借位链
        borrow_chain = {WIDTH{1'b0}};
        
        // 如果是负数，设置符号扩展位
        if (sign_bit) begin
            // 使用借位减法器的概念替代掩码生成
            case (effective_shift)
                3'd1: borrow_chain = {{1{1'b1}}, {(WIDTH-1){1'b0}}};
                3'd2: borrow_chain = {{2{1'b1}}, {(WIDTH-2){1'b0}}};
                3'd3: borrow_chain = {{3{1'b1}}, {(WIDTH-3){1'b0}}};
                3'd4: borrow_chain = (WIDTH >= 4) ? {{4{1'b1}}, {(WIDTH-4){1'b0}}} : {WIDTH{1'b1}};
                3'd5: borrow_chain = (WIDTH >= 5) ? {{5{1'b1}}, {(WIDTH-5){1'b0}}} : {WIDTH{1'b1}};
                3'd6: borrow_chain = (WIDTH >= 6) ? {{6{1'b1}}, {(WIDTH-6){1'b0}}} : {WIDTH{1'b1}};
                3'd7: borrow_chain = (WIDTH >= 7) ? {{7{1'b1}}, {(WIDTH-7){1'b0}}} : {WIDTH{1'b1}};
                default: borrow_chain = {WIDTH{1'b0}};
            endcase
        end
        
        // 实现借位减法器概念的算术右移
        // 首先进行逻辑右移，然后根据借位链添加符号位
        shift_result = (data_in >> effective_shift) | (borrow_chain << (WIDTH - effective_shift));
    end

    always @(posedge clk) begin
        case(state)
            IDLE: begin
                if (shift_en) state <= SHIFT;
                else if (rst) state <= RESET;
            end
            SHIFT: begin
                result <= shift_result;
                if (rst) state <= RESET;
                else if (!shift_en) state <= IDLE;
            end
            RESET: begin
                result <= 0;
                if (!rst) state <= IDLE;
            end
            default: state <= IDLE;
        endcase
    end
endmodule