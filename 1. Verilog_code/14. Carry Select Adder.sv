module carry_select_adder(
    input [3:0] a,b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [1:0] sum_low, sum_high0, sum_high1;
    wire carry_low, carry_high0, carry_high1;

    // Lower 2 bits
    assign {carry_low, sum_low} = a[1:0] + b[1:0] + cin;
    
    // Upper bits with carry 0 and 1
    assign {carry_high0, sum_high0} = a[3:2] + b[3:2] + 0;
    assign {carry_high1, sum_high1} = a[3:2] + b[3:2] + 1;
    
    // Mux selection
    assign sum = {carry_low ? sum_high1 : sum_high0, sum_low};
    assign cout = carry_low ? carry_high1 : carry_high0;
endmodule