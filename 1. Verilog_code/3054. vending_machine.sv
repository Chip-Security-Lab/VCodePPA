module vending_machine(
    input wire clk, rst,
    input wire [1:0] coin, // 00:none, 01:5¢, 10:10¢, 11:25¢
    output reg dispense
);
    reg [4:0] state, next_state;
    
    always @(posedge clk or posedge rst)
        if (rst) state <= 5'd0;
        else state <= next_state;
    
    always @(*) begin
        dispense = 1'b0;
        casez ({state, coin})
            {5'd0, 2'b01}: next_state = 5'd5;
            {5'd0, 2'b10}: next_state = 5'd10;
            {5'd0, 2'b11}: next_state = 5'd25;
            {5'd5, 2'b01}: next_state = 5'd10;
            {5'd5, 2'b10}: next_state = 5'd15;
            {5'd5, 2'b11}: next_state = 5'd30;
            {5'd10, 2'b01}: next_state = 5'd15;
            {5'd10, 2'b10}: next_state = 5'd20;
            {5'd10, 2'b11}: next_state = 5'd0;
            {5'd15, 2'b01}: next_state = 5'd20;
            {5'd15, 2'b10}: next_state = 5'd25;
            {5'd15, 2'b11}: next_state = 5'd0;
            {5'd20, 2'b??}: next_state = 5'd0;
            {5'd25, 2'b??}: next_state = 5'd0;
            {5'd30, 2'b??}: next_state = 5'd0;
            default: next_state = state;
        endcase
        if ((state >= 5'd20 && state < 5'd30 && coin != 2'b00) ||
            (state >= 5'd30)) dispense = 1'b1;
    end
endmodule