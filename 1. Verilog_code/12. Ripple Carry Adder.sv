module ripple_adder(
    input [3:0] a,b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [4:0] c;
    assign c[0] = cin;
    
    generate
        genvar i;
        for(i=0;i<4;i=i+1) begin: stage
            full_adder fa(a[i],b[i],c[i],sum[i],c[i+1]);
        end
    endgenerate
    
    assign cout = c[4];
endmodule

module full_adder(input a,b,cin, output sum,cout);
    assign {cout,sum} = a + b + cin;
endmodule