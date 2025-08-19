//SystemVerilog
module sync_divider_4bit (
    input clk,
    input reset,
    input req,
    output reg ack,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] quotient
);

    reg req_reg;
    reg ack_reg;
    reg [3:0] quotient_reg;
    reg [3:0] a_reg;
    reg [3:0] b_reg;
    reg [3:0] div_result;
    reg div_valid;
    
    // 提前计算除法结果
    always @(*) begin
        div_result = a_reg / b_reg;
        div_valid = (b_reg != 0);
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            ack <= 0;
            req_reg <= 0;
            ack_reg <= 0;
            quotient_reg <= 0;
            a_reg <= 0;
            b_reg <= 0;
        end else begin
            req_reg <= req;
            ack_reg <= ack;
            
            // 提前锁存输入数据
            if (req && !ack) begin
                a_reg <= a;
                b_reg <= b;
            end
            
            // 状态机逻辑优化
            case ({req, ack})
                2'b10: begin
                    if (div_valid) begin
                        quotient_reg <= div_result;
                        ack <= 1;
                    end
                end
                2'b01: begin
                    ack <= 0;
                end
                default: begin
                    quotient_reg <= quotient_reg;
                end
            endcase
            
            quotient <= quotient_reg;
        end
    end
endmodule