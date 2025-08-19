module recursive_cs_block #(parameter N=8)(
    input [N-1:0] a,b,
    input cin0, cin1,
    output [N-1:0] sum0, sum1,
    output cout0, cout1
);
    generate
        if(N == 1) begin
            assign {cout0,sum0} = a + b + cin0;
            assign {cout1,sum1} = a + b + cin1;
        end else begin
            localparam N_LOW = N/2;
            localparam N_HIGH = N - N_LOW;

            wire [N_LOW-1:0] sum0_low, sum1_low;
            wire cout0_low, cout1_low;

            recursive_cs_block #(N_LOW) low_part (
                .a(a[N_LOW-1:0]),
                .b(b[N_LOW-1:0]),
                .cin0(cin0),
                .cin1(cin1),
                .sum0(sum0_low),
                .sum1(sum1_low),
                .cout0(cout0_low),
                .cout1(cout1_low)
            );

            wire [N_HIGH-1:0] sum0_high, sum1_high;
            wire cout0_high, cout1_high;

            // The carry-in for the high part when overall cin is cin0 is cout0_low
            // The carry-in for the high part when overall cin is cin1 is cout1_low
            recursive_cs_block #(N_HIGH) high_part (
                .a(a[N-1:N_LOW]),
                .b(b[N-1:N_LOW]),
                .cin0(cout0_low),
                .cin1(cout1_low),
                .sum0(sum0_high),
                .sum1(sum1_high),
                .cout0(cout0_high),
                .cout1(cout1_high)
            );

            assign sum0 = {sum0_high, sum0_low};
            assign sum1 = {sum1_high, sum1_low};
            assign cout0 = cout0_high;
            assign cout1 = cout1_high;
        end
    endgenerate
endmodule

module recursive_adder #(parameter N=8)(
    input [N-1:0] a,b,
    input cin,
    output wire [N-1:0] sum,
    output wire cout
);
    // Instantiate the recursive carry-select block
    wire [N-1:0] sum_for_cin0, sum_for_cin1;
    wire cout_for_cin0, cout_for_cin1;

    recursive_cs_block #(N) main_block (
        .a(a),
        .b(b),
        .cin0(1'b0), // Calculate sum/cout assuming overall cin is 0
        .cin1(1'b1), // Calculate sum/cout assuming overall cin is 1
        .sum0(sum_for_cin0),
        .sum1(sum_for_cin1),
        .cout0(cout_for_cin0),
        .cout1(cout_for_cin1)
    );

    // Select the final sum and cout based on the actual cin using multiplexers
    assign sum = cin ? sum_for_cin1 : sum_for_cin0;
    assign cout = cin ? cout_for_cin1 : cout_for_cin0;

endmodule