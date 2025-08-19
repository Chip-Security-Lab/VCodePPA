//SystemVerilog
module freq_divider(
    input wire clk_in, rst_n,
    input wire [15:0] div_ratio,
    input wire update_ratio,
    output reg clk_out
);
    localparam IDLE=1'b0, DIVIDE=1'b1;
    reg state, next;
    reg [15:0] counter;
    reg [15:0] div_value;
    reg [15:0] quotient_stage1, quotient_stage2, quotient_stage3;
    reg [15:0] remainder_stage1, remainder_stage2, remainder_stage3;
    reg [15:0] dividend_stage1, dividend_stage2, dividend_stage3;
    reg [15:0] divisor_stage1, divisor_stage2, divisor_stage3;
    reg [4:0] div_step_stage1, div_step_stage2, div_step_stage3;
    reg div_start_stage1, div_start_stage2, div_start_stage3;
    reg div_done_stage1, div_done_stage2, div_done_stage3;
    
    localparam DIV_IDLE = 2'b00;
    localparam DIV_CALC = 2'b01;
    localparam DIV_DONE = 2'b10;
    reg [1:0] div_state_stage1, div_state_stage2, div_state_stage3;
    
    always @(posedge clk_in or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            counter <= 16'd0;
            div_value <= 16'd2;
            clk_out <= 1'b0;
            div_state_stage1 <= DIV_IDLE;
            div_state_stage2 <= DIV_IDLE;
            div_state_stage3 <= DIV_IDLE;
            div_start_stage1 <= 1'b0;
            div_start_stage2 <= 1'b0;
            div_start_stage3 <= 1'b0;
            div_done_stage1 <= 1'b0;
            div_done_stage2 <= 1'b0;
            div_done_stage3 <= 1'b0;
            quotient_stage1 <= 16'd0;
            quotient_stage2 <= 16'd0;
            quotient_stage3 <= 16'd0;
            remainder_stage1 <= 16'd0;
            remainder_stage2 <= 16'd0;
            remainder_stage3 <= 16'd0;
            dividend_stage1 <= 16'd0;
            dividend_stage2 <= 16'd0;
            dividend_stage3 <= 16'd0;
            divisor_stage1 <= 16'd0;
            divisor_stage2 <= 16'd0;
            divisor_stage3 <= 16'd0;
            div_step_stage1 <= 5'd0;
            div_step_stage2 <= 5'd0;
            div_step_stage3 <= 5'd0;
        end else begin
            state <= next;
            
            if (update_ratio)
                div_value <= (div_ratio < 16'd2) ? 16'd2 : div_ratio;
                
            case (state)
                IDLE: begin
                    counter <= 16'd0;
                    div_start_stage1 <= 1'b1;
                end
                DIVIDE: begin
                    div_start_stage1 <= 1'b0;
                    if (div_done_stage3) begin
                        counter <= counter + 16'd1;
                        if (counter >= (quotient_stage3 - 1)) begin
                            counter <= 16'd0;
                            clk_out <= ~clk_out;
                            div_start_stage1 <= 1'b1;
                        end
                    end
                end
            endcase
            
            // Stage 1: Initialization and first calculation
            case (div_state_stage1)
                DIV_IDLE: begin
                    if (div_start_stage1) begin
                        dividend_stage1 <= div_value;
                        divisor_stage1 <= 16'd2;
                        div_step_stage1 <= 5'd0;
                        div_state_stage1 <= DIV_CALC;
                        div_done_stage1 <= 1'b0;
                    end
                end
                
                DIV_CALC: begin
                    if (div_step_stage1 < 5'd5) begin
                        remainder_stage1 <= {remainder_stage1[14:0], dividend_stage1[15]};
                        dividend_stage1 <= {dividend_stage1[14:0], 1'b0};
                        
                        if (remainder_stage1 >= divisor_stage1) begin
                            remainder_stage1 <= remainder_stage1 - divisor_stage1;
                            quotient_stage1 <= {quotient_stage1[14:0], 1'b1};
                        end else begin
                            quotient_stage1 <= {quotient_stage1[14:0], 1'b0};
                        end
                        
                        div_step_stage1 <= div_step_stage1 + 5'd1;
                    end else begin
                        div_state_stage1 <= DIV_DONE;
                    end
                end
                
                DIV_DONE: begin
                    div_done_stage1 <= 1'b1;
                    div_state_stage1 <= DIV_IDLE;
                end
            endcase
            
            // Stage 2: Middle calculation
            case (div_state_stage2)
                DIV_IDLE: begin
                    if (div_done_stage1) begin
                        dividend_stage2 <= dividend_stage1;
                        divisor_stage2 <= divisor_stage1;
                        remainder_stage2 <= remainder_stage1;
                        quotient_stage2 <= quotient_stage1;
                        div_step_stage2 <= div_step_stage1;
                        div_state_stage2 <= DIV_CALC;
                        div_done_stage2 <= 1'b0;
                    end
                end
                
                DIV_CALC: begin
                    if (div_step_stage2 < 5'd11) begin
                        remainder_stage2 <= {remainder_stage2[14:0], dividend_stage2[15]};
                        dividend_stage2 <= {dividend_stage2[14:0], 1'b0};
                        
                        if (remainder_stage2 >= divisor_stage2) begin
                            remainder_stage2 <= remainder_stage2 - divisor_stage2;
                            quotient_stage2 <= {quotient_stage2[14:0], 1'b1};
                        end else begin
                            quotient_stage2 <= {quotient_stage2[14:0], 1'b0};
                        end
                        
                        div_step_stage2 <= div_step_stage2 + 5'd1;
                    end else begin
                        div_state_stage2 <= DIV_DONE;
                    end
                end
                
                DIV_DONE: begin
                    div_done_stage2 <= 1'b1;
                    div_state_stage2 <= DIV_IDLE;
                end
            endcase
            
            // Stage 3: Final calculation
            case (div_state_stage3)
                DIV_IDLE: begin
                    if (div_done_stage2) begin
                        dividend_stage3 <= dividend_stage2;
                        divisor_stage3 <= divisor_stage2;
                        remainder_stage3 <= remainder_stage2;
                        quotient_stage3 <= quotient_stage2;
                        div_step_stage3 <= div_step_stage2;
                        div_state_stage3 <= DIV_CALC;
                        div_done_stage3 <= 1'b0;
                    end
                end
                
                DIV_CALC: begin
                    if (div_step_stage3 < 5'd16) begin
                        remainder_stage3 <= {remainder_stage3[14:0], dividend_stage3[15]};
                        dividend_stage3 <= {dividend_stage3[14:0], 1'b0};
                        
                        if (remainder_stage3 >= divisor_stage3) begin
                            remainder_stage3 <= remainder_stage3 - divisor_stage3;
                            quotient_stage3 <= {quotient_stage3[14:0], 1'b1};
                        end else begin
                            quotient_stage3 <= {quotient_stage3[14:0], 1'b0};
                        end
                        
                        div_step_stage3 <= div_step_stage3 + 5'd1;
                    end else begin
                        div_state_stage3 <= DIV_DONE;
                    end
                end
                
                DIV_DONE: begin
                    div_done_stage3 <= 1'b1;
                    div_state_stage3 <= DIV_IDLE;
                end
            endcase
        end
    
    always @(*)
        case (state)
            IDLE: next = DIVIDE;
            DIVIDE: next = DIVIDE;
            default: next = IDLE;
        endcase
endmodule