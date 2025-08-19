//SystemVerilog
module vending_machine(
    input wire clock,
    input wire n_reset,
    input wire [1:0] coin, // 01:5¢, 10:10¢, 11:25¢
    input wire product_select,
    output reg dispense,
    output reg [5:0] change_amount
);
    parameter [1:0] IDLE = 2'b00, COLLECT = 2'b01, DISPENSE_STATE = 2'b10;
    parameter PRICE = 6'd30; // 30¢
    
    // Pipeline stage 1 registers
    reg [1:0] state_stage1, next_state_stage1;
    reg [5:0] credit_stage1, next_credit_stage1;
    reg [1:0] coin_stage1;
    reg product_select_stage1;
    
    // Pipeline stage 2 registers
    reg [1:0] state_stage2, next_state_stage2;
    reg [5:0] credit_stage2, next_credit_stage2;
    reg product_select_stage2;
    
    // Pipeline stage 3 registers
    reg [1:0] state_stage3;
    reg [5:0] credit_stage3;
    reg dispense_stage3;
    reg [5:0] change_amount_stage3;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Stage 1: Input capture and initial processing
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            state_stage1 <= IDLE;
            credit_stage1 <= 0;
            valid_stage1 <= 1'b0;
        end else begin
            state_stage1 <= next_state_stage1;
            credit_stage1 <= next_credit_stage1;
            coin_stage1 <= coin;
            product_select_stage1 <= product_select;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 1 combinational logic
    always @(*) begin
        next_state_stage1 = state_stage1;
        next_credit_stage1 = credit_stage1;
        
        if (state_stage1 == IDLE && coin_stage1 != 2'b00) begin
            next_state_stage1 = COLLECT;
            next_credit_stage1 = (coin_stage1 == 2'b01) ? 6'd5 : 
                               (coin_stage1 == 2'b10) ? 6'd10 : 6'd25;
        end
        else if (state_stage1 == COLLECT) begin
            if (coin_stage1 != 2'b00) begin
                next_credit_stage1 = credit_stage1 + ((coin_stage1 == 2'b01) ? 6'd5 : 
                                                    (coin_stage1 == 2'b10) ? 6'd10 : 6'd25);
            end
            if (product_select_stage1 && credit_stage1 >= PRICE) begin
                next_state_stage1 = DISPENSE_STATE;
            end
        end
    end
    
    // Stage 2: Intermediate processing
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            state_stage2 <= IDLE;
            credit_stage2 <= 0;
            valid_stage2 <= 1'b0;
        end else begin
            state_stage2 <= next_state_stage2;
            credit_stage2 <= next_credit_stage2;
            product_select_stage2 <= product_select_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 2 combinational logic
    always @(*) begin
        next_state_stage2 = state_stage2;
        next_credit_stage2 = credit_stage2;
        
        if (state_stage2 == DISPENSE_STATE) begin
            next_state_stage2 = IDLE;
            next_credit_stage2 = 6'd0;
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            state_stage3 <= IDLE;
            credit_stage3 <= 0;
            dispense_stage3 <= 1'b0;
            change_amount_stage3 <= 6'd0;
            valid_stage3 <= 1'b0;
        end else begin
            state_stage3 <= state_stage2;
            credit_stage3 <= credit_stage2;
            dispense_stage3 <= (state_stage2 == DISPENSE_STATE);
            change_amount_stage3 <= (state_stage2 == DISPENSE_STATE) ? (credit_stage2 - PRICE) : 6'd0;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignments
    assign dispense = valid_stage3 ? dispense_stage3 : 1'b0;
    assign change_amount = valid_stage3 ? change_amount_stage3 : 6'd0;
    
endmodule