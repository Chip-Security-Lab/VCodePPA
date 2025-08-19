//SystemVerilog
module divider_16bit (
    input [15:0] dividend,
    input [15:0] divisor,
    input clk,
    input rst_n,
    input valid_in,           // 替代start信号
    output reg ready_in,      // 新增接收方ready信号
    output reg [15:0] quotient,
    output reg [15:0] remainder,
    output reg overflow,
    output reg valid_out,     // 替代done信号
    input ready_out          // 新增接收方ready信号
);

    // Internal registers
    reg [15:0] dividend_reg;
    reg [15:0] divisor_reg;
    reg [15:0] quotient_reg;
    reg [15:0] remainder_reg;
    reg [4:0] bit_counter;
    reg result_valid;        // 内部信号表示计算结果有效
    reg result_consumed;     // 标记结果是否被消费
    
    // State machine
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam FINISH = 2'b10;
    reg [1:0] state, next_state;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            state <= IDLE;
        else 
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = (valid_in && ready_in) ? COMPUTE : IDLE;
            COMPUTE: next_state = (bit_counter == 0) ? FINISH : COMPUTE;
            FINISH: next_state = (valid_out && ready_out) ? IDLE : FINISH;
            default: next_state = IDLE;
        endcase
    end

    // Datapath
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_reg <= 0;
            divisor_reg <= 0;
            quotient_reg <= 0;
            remainder_reg <= 0;
            bit_counter <= 0;
            ready_in <= 1;         // 初始状态下可以接收新数据
            valid_out <= 0;
            overflow <= 0;
            quotient <= 0;
            remainder <= 0;
            result_valid <= 0;
            result_consumed <= 1;
        end else begin
            case (state)
                IDLE: begin
                    // 在IDLE状态下表示可以接收新数据
                    ready_in <= 1;
                    
                    if (valid_in && ready_in) begin
                        // 握手成功，接收新数据
                        if (divisor == 0) begin
                            overflow <= 1;
                            quotient <= 0;
                            remainder <= 0;
                            valid_out <= 1;
                            ready_in <= 0;
                            result_valid <= 1;
                            result_consumed <= 0;
                        end else begin
                            dividend_reg <= dividend;
                            divisor_reg <= divisor;
                            quotient_reg <= 0;
                            remainder_reg <= 0;
                            bit_counter <= 16;  // 16-bit division requires 16 steps
                            overflow <= 0;
                            ready_in <= 0;      // 计算过程中不接收新数据
                            valid_out <= 0;
                        end
                    end
                end

                COMPUTE: begin
                    // Shift remainder left and bring in next bit from dividend
                    remainder_reg <= {remainder_reg[14:0], dividend_reg[15]};
                    dividend_reg <= {dividend_reg[14:0], 1'b0};
                    
                    // Perform subtraction if remainder >= divisor
                    if ({remainder_reg[14:0], dividend_reg[15]} >= divisor_reg) begin
                        remainder_reg <= {remainder_reg[14:0], dividend_reg[15]} - divisor_reg;
                        quotient_reg <= {quotient_reg[14:0], 1'b1};
                    end else begin
                        quotient_reg <= {quotient_reg[14:0], 1'b0};
                    end
                    
                    bit_counter <= bit_counter - 1;
                end

                FINISH: begin
                    // 结果已计算完成
                    if (!result_valid) begin
                        quotient <= quotient_reg;
                        remainder <= remainder_reg;
                        valid_out <= 1;           // 表示输出数据有效
                        result_valid <= 1;
                    end
                    
                    // 等待下游模块接收数据
                    if (valid_out && ready_out) begin
                        valid_out <= 0;           // 握手成功，清除valid信号
                        result_consumed <= 1;
                        result_valid <= 0;
                    end
                end
            endcase
        end
    end

endmodule