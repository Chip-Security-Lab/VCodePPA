//SystemVerilog
module fsm_divider (
    input clk_input, reset,
    output clk_output
);
    reg [1:0] state;
    reg clk_out_reg;
    
    localparam S0 = 2'b00, S1 = 2'b01, 
               S2 = 2'b10, S3 = 2'b11;
    
    // 优化后直接在时序块内计算下一状态并更新输出
    always @(posedge clk_input) begin
        if (reset) begin
            state <= S0;
            clk_out_reg <= 1'b1; // S0状态对应输出为1
        end
        else begin
            case(state)
                S0: begin
                    state <= S1;
                    clk_out_reg <= 1'b1; // S1状态对应输出为1
                end
                S1: begin
                    state <= S2;
                    clk_out_reg <= 1'b0; // S2状态对应输出为0
                end
                S2: begin
                    state <= S3;
                    clk_out_reg <= 1'b0; // S3状态对应输出为0
                end
                S3: begin
                    state <= S0;
                    clk_out_reg <= 1'b1; // S0状态对应输出为1
                end
                default: begin
                    state <= S0;
                    clk_out_reg <= 1'b1;
                end
            endcase
        end
    end
    
    assign clk_output = clk_out_reg;
endmodule