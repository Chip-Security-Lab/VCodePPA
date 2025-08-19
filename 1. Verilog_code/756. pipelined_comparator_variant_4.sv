//SystemVerilog
// 顶层模块
module pipelined_divider #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] data_x,
    input wire [WIDTH-1:0] data_y,
    output reg equal,
    output reg greater,
    output reg less
);

    // 内部信号
    wire [WIDTH-1:0] quotient;
    wire [WIDTH-1:0] remainder;
    wire div_by_zero;
    wire calc_done;

    // 控制模块实例化
    divider_control #(WIDTH) control_inst (
        .clk(clk),
        .rst(rst),
        .data_x(data_x),
        .data_y(data_y),
        .quotient(quotient),
        .remainder(remainder),
        .div_by_zero(div_by_zero),
        .calc_done(calc_done)
    );

    // 结果处理模块实例化
    result_processor #(WIDTH) result_inst (
        .clk(clk),
        .rst(rst),
        .quotient(quotient),
        .div_by_zero(div_by_zero),
        .calc_done(calc_done),
        .equal(equal),
        .greater(greater),
        .less(less)
    );

endmodule

// 控制模块
module divider_control #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] data_x,
    input wire [WIDTH-1:0] data_y,
    output reg [WIDTH-1:0] quotient,
    output reg [WIDTH-1:0] remainder,
    output reg div_by_zero,
    output reg calc_done
);

    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [WIDTH-1:0] dividend_reg;
    reg [WIDTH-1:0] divisor_reg;
    reg [WIDTH:0] partial_reg;
    reg [3:0] bit_counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            dividend_reg <= {WIDTH{1'b0}};
            divisor_reg <= {WIDTH{1'b0}};
            quotient <= {WIDTH{1'b0}};
            remainder <= {WIDTH{1'b0}};
            partial_reg <= {(WIDTH+1){1'b0}};
            bit_counter <= 4'b0;
            div_by_zero <= 1'b0;
            calc_done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    dividend_reg <= data_x;
                    divisor_reg <= data_y;
                    quotient <= {WIDTH{1'b0}};
                    remainder <= {WIDTH{1'b0}};
                    partial_reg <= {(WIDTH+1){1'b0}};
                    bit_counter <= WIDTH;
                    div_by_zero <= (data_y == 0);
                    state <= CALC;
                end
                
                CALC: begin
                    if (bit_counter == 0 || div_by_zero) begin
                        remainder <= partial_reg[WIDTH-1:0];
                        state <= DONE;
                    end else begin
                        partial_reg <= {partial_reg[WIDTH-1:0], dividend_reg[WIDTH-1]};
                        dividend_reg <= {dividend_reg[WIDTH-2:0], 1'b0};
                        
                        if ({partial_reg[WIDTH-1:0], dividend_reg[WIDTH-1]} >= divisor_reg) begin
                            partial_reg <= {partial_reg[WIDTH-1:0], dividend_reg[WIDTH-1]} - divisor_reg;
                            quotient <= {quotient[WIDTH-2:0], 1'b1};
                        end else begin
                            quotient <= {quotient[WIDTH-2:0], 1'b0};
                        end
                        
                        bit_counter <= bit_counter - 1;
                    end
                end
                
                DONE: begin
                    calc_done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule

// 结果处理模块
module result_processor #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] quotient,
    input wire div_by_zero,
    input wire calc_done,
    output reg equal,
    output reg greater,
    output reg less
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            equal <= 1'b0;
            greater <= 1'b0;
            less <= 1'b0;
        end else if (calc_done) begin
            if (div_by_zero) begin
                equal <= 1'b0;
                greater <= 1'b0;
                less <= 1'b1;
            end else begin
                equal <= (quotient == 0);
                greater <= (quotient > 0);
                less <= 1'b0;
            end
        end
    end
endmodule