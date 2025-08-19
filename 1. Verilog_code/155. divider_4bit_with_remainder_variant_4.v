module divider_4bit_with_remainder (
    input clk,
    input rst_n,
    input valid_i,
    output ready_o,
    input [3:0] dividend,
    input [3:0] divisor,
    output reg valid_o,
    input ready_i,
    output reg [3:0] quotient,
    output reg [3:0] remainder
);

    // Pipeline stage registers
    reg [3:0] dividend_stage1, dividend_stage2, dividend_stage3, dividend_stage4;
    reg [3:0] divisor_stage1, divisor_stage2, divisor_stage3, divisor_stage4;
    reg [3:0] quotient_stage1, quotient_stage2, quotient_stage3, quotient_stage4;
    reg [3:0] remainder_stage1, remainder_stage2, remainder_stage3, remainder_stage4;
    
    // Control signals
    reg div_start;
    reg div_done;
    reg [1:0] state_stage1, state_stage2, state_stage3, state_stage4;
    reg [2:0] count_stage1, count_stage2, count_stage3, count_stage4;
    
    // Division state machine
    localparam IDLE = 2'b00;
    localparam DIVIDE = 2'b01;
    localparam DONE = 2'b10;
    
    // Handshake control
    reg data_valid;
    reg result_ready;
    
    assign ready_o = (state_stage4 == IDLE) && !data_valid;
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            count_stage1 <= 3'b0;
            dividend_stage1 <= 4'b0;
            divisor_stage1 <= 4'b0;
            quotient_stage1 <= 4'b0;
            remainder_stage1 <= 4'b0;
            data_valid <= 1'b0;
        end else begin
            if (state_stage1 == IDLE && valid_i && ready_o) begin
                dividend_stage1 <= dividend;
                divisor_stage1 <= divisor;
                quotient_stage1 <= 4'b0;
                remainder_stage1 <= 4'b0;
                count_stage1 <= 3'b0;
                state_stage1 <= DIVIDE;
                data_valid <= 1'b1;
            end
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            count_stage2 <= 3'b0;
            dividend_stage2 <= 4'b0;
            divisor_stage2 <= 4'b0;
            quotient_stage2 <= 4'b0;
            remainder_stage2 <= 4'b0;
        end else begin
            state_stage2 <= state_stage1;
            count_stage2 <= count_stage1;
            dividend_stage2 <= dividend_stage1;
            divisor_stage2 <= divisor_stage1;
            quotient_stage2 <= quotient_stage1;
            remainder_stage2 <= remainder_stage1;
        end
    end
    
    // Pipeline stage 3 - Division computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            count_stage3 <= 3'b0;
            dividend_stage3 <= 4'b0;
            divisor_stage3 <= 4'b0;
            quotient_stage3 <= 4'b0;
            remainder_stage3 <= 4'b0;
        end else begin
            state_stage3 <= state_stage2;
            count_stage3 <= count_stage2;
            
            if (state_stage2 == DIVIDE && count_stage2 < 4) begin
                remainder_stage3 <= {remainder_stage2[2:0], dividend_stage2[3]};
                dividend_stage3 <= {dividend_stage2[2:0], 1'b0};
                
                if (remainder_stage2 >= divisor_stage2) begin
                    remainder_stage3 <= remainder_stage2 - divisor_stage2;
                    quotient_stage3 <= {quotient_stage2[2:0], 1'b1};
                end else begin
                    quotient_stage3 <= {quotient_stage2[2:0], 1'b0};
                end
                
                count_stage3 <= count_stage2 + 1;
            end else begin
                dividend_stage3 <= dividend_stage2;
                divisor_stage3 <= divisor_stage2;
                quotient_stage3 <= quotient_stage2;
                remainder_stage3 <= remainder_stage2;
            end
        end
    end
    
    // Pipeline stage 4 - Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage4 <= IDLE;
            count_stage4 <= 3'b0;
            dividend_stage4 <= 4'b0;
            divisor_stage4 <= 4'b0;
            quotient_stage4 <= 4'b0;
            remainder_stage4 <= 4'b0;
            div_done <= 1'b0;
            valid_o <= 1'b0;
            result_ready <= 1'b0;
        end else begin
            state_stage4 <= state_stage3;
            count_stage4 <= count_stage3;
            dividend_stage4 <= dividend_stage3;
            divisor_stage4 <= divisor_stage3;
            quotient_stage4 <= quotient_stage3;
            remainder_stage4 <= remainder_stage3;
            
            if (state_stage3 == DONE) begin
                quotient <= quotient_stage3;
                remainder <= remainder_stage3;
                div_done <= 1'b1;
                valid_o <= 1'b1;
                if (ready_i) begin
                    result_ready <= 1'b1;
                    valid_o <= 1'b0;
                end
            end else begin
                div_done <= 1'b0;
                if (result_ready) begin
                    valid_o <= 1'b0;
                    result_ready <= 1'b0;
                end
            end
        end
    end
    
    // Control logic
    always @(*) begin
        div_start = (state_stage4 == IDLE) && !data_valid;
    end

endmodule