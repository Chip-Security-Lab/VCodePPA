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
    
    // Coin value lookup table
    wire [5:0] coin_value = (coin == 2'b01) ? 6'd5 :
                           (coin == 2'b10) ? 6'd10 :
                           (coin == 2'b11) ? 6'd25 : 6'd0;
    
    // State machine registers
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            state <= IDLE;
            credit <= 0;
        end else begin
            state <= next_state;
            credit <= next_credit;
        end
    end
    
    // Next state and output logic
    always @(*) begin
        next_state = state;
        next_credit = credit;
        dispense = 1'b0;
        change_amount = 6'd0;
        
        case (state)
            IDLE: begin
                if (|coin) begin
                    next_state = COLLECT;
                    next_credit = coin_value;
                end
            end
            COLLECT: begin
                if (|coin) begin
                    next_credit = credit + coin_value;
                end
                if (product_select && credit >= PRICE) begin
                    next_state = DISPENSE_STATE;
                end
            end
            DISPENSE_STATE: begin
                dispense = 1'b1;
                change_amount = credit - PRICE;
                next_credit = 6'd0;
                next_state = IDLE;
            end
        endcase
    end
endmodule