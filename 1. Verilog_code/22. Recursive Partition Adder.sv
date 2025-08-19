module recursive_adder #(parameter N=8)(
    input [N-1:0] a,b,
    input cin,
    output [N-1:0] sum,
    output cout
);
    generate
        if(N == 1) begin
            assign {cout,sum} = a + b + cin;
        end else begin
            wire carry;
            recursive_adder #(N/2) low(a[N/2-1:0],b[N/2-1:0],cin,sum[N/2-1:0],carry);
            recursive_adder #(N-N/2) high(a[N-1:N/2],b[N-1:N/2],carry,sum[N-1:N/2],cout);
        end
    endgenerate
endmodule