//SystemVerilog
module divider_16bit_unsigned (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] a,
    input  wire [15:0] b,
    output reg  [15:0] quotient,
    output reg  [15:0] remainder,
    output reg         valid
);

    // 实例化除法器核心模块
    divider_core #(
        .WIDTH(16)
    ) u_divider_core (
        .clk(clk),
        .rst_n(rst_n),
        .dividend(a),
        .divisor(b),
        .quotient(quotient),
        .remainder(remainder),
        .valid(valid)
    );

endmodule

// 除法器核心模块
module divider_core #(
    parameter WIDTH = 16
) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire [WIDTH-1:0]    dividend,
    input  wire [WIDTH-1:0]    divisor,
    output reg  [WIDTH-1:0]    quotient,
    output reg  [WIDTH-1:0]    remainder,
    output reg                 valid
);

    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [WIDTH-1:0] q_reg;
    reg [WIDTH-1:0] r_reg;
    reg [WIDTH-1:0] d_reg;
    reg [WIDTH-1:0] s_reg;
    reg [4:0] count;
    reg calc_done;
    
    // 状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: next_state = CALC;
            CALC: if (calc_done) next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 数据处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_reg <= 0;
            r_reg <= 0;
            d_reg <= 0;
            s_reg <= 0;
            count <= 0;
            calc_done <= 0;
            valid <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    q_reg <= 0;
                    r_reg <= 0;
                    d_reg <= dividend;
                    s_reg <= divisor;
                    count <= 0;
                    calc_done <= 0;
                    valid <= 0;
                end
                
                CALC: begin
                    if (count < WIDTH) begin
                        r_reg <= {r_reg[WIDTH-2:0], d_reg[WIDTH-1-count]};
                        if (r_reg >= s_reg) begin
                            r_reg <= r_reg - s_reg;
                            q_reg[WIDTH-1-count] <= 1'b1;
                        end
                        count <= count + 1;
                    end
                    else begin
                        calc_done <= 1'b1;
                    end
                end
                
                DONE: begin
                    quotient <= q_reg;
                    remainder <= r_reg;
                    valid <= 1'b1;
                end
                
                default: begin
                    q_reg <= 0;
                    r_reg <= 0;
                    d_reg <= 0;
                    s_reg <= 0;
                    count <= 0;
                    calc_done <= 0;
                    valid <= 0;
                end
            endcase
        end
    end

endmodule