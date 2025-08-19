//SystemVerilog
module config_div #(parameter MODE=0) (
    input clk, rst,
    output clk_out
);
    localparam DIV = (MODE) ? 8 : 16;
    
    reg clk_out_reg;
    reg [4:0] iteration_count;
    reg [4:0] divisor;
    reg [4:0] reciprocal;
    reg [9:0] temp_product;
    reg div_complete;
    reg [2:0] goldschmidt_iter;
    
    // Goldschmidt 算法状态
    localparam IDLE = 2'b00;
    localparam CALCULATE = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // 状态机逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            clk_out_reg <= 0;
            iteration_count <= 0;
            divisor <= DIV;
            reciprocal <= 5'b00001;
            goldschmidt_iter <= 0;
            div_complete <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    iteration_count <= 0;
                    divisor <= DIV;
                    reciprocal <= 5'b00001;
                    goldschmidt_iter <= 0;
                    div_complete <= 0;
                end
                
                CALCULATE: begin
                    // Goldschmidt 迭代
                    if (goldschmidt_iter < 3) begin
                        // 2 - divisor * reciprocal
                        temp_product <= divisor * reciprocal;
                        divisor <= divisor * (10'b1000000000 - (divisor * reciprocal)) >> 5;
                        reciprocal <= reciprocal * (10'b1000000000 - (divisor * reciprocal)) >> 5;
                        goldschmidt_iter <= goldschmidt_iter + 1;
                    end else begin
                        div_complete <= 1;
                    end
                end
                
                DONE: begin
                    if (iteration_count >= reciprocal - 1) begin
                        clk_out_reg <= ~clk_out_reg;
                        iteration_count <= 0;
                    end else begin
                        iteration_count <= iteration_count + 1;
                    end
                end
            endcase
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = CALCULATE;
            CALCULATE: next_state = div_complete ? DONE : CALCULATE;
            DONE: next_state = DONE;
            default: next_state = IDLE;
        endcase
    end
    
    // 输出赋值
    assign clk_out = clk_out_reg;
    
endmodule