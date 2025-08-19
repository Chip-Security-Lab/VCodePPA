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
    reg [1:0] state, next_state;
    reg [5:0] credit, next_credit;
    parameter PRICE = 6'd30; // 30¢
    
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            state <= IDLE;
            credit <= 0;
        end else begin
            state <= next_state;
            credit <= next_credit;
        end
    end
    
    always @(*) begin
        next_state = state;
        next_credit = credit;
        dispense = 1'b0;
        change_amount = 6'd0;
        
        if (state == IDLE) begin
            if (coin != 2'b00) begin
                next_state = COLLECT;
                if (coin == 2'b01) next_credit = 6'd5;
                else if (coin == 2'b10) next_credit = 6'd10;
                else if (coin == 2'b11) next_credit = 6'd25;
            end
        end else if (state == COLLECT) begin
            if (coin != 2'b00) begin
                if (coin == 2'b01) next_credit = credit + 6'd5;
                else if (coin == 2'b10) next_credit = credit + 6'd10;
                else if (coin == 2'b11) next_credit = credit + 6'd25;
            end
            if (product_select && credit >= PRICE) begin
                next_state = DISPENSE_STATE;
            end
        end else if (state == DISPENSE_STATE) begin
            dispense = 1'b1;
            change_amount = credit - PRICE;
            next_credit = 6'd0;
            next_state = IDLE;
        end
    end
endmodule