// Top-level module
module carry_select_adder(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  a,
    input  wire [3:0]  b,
    input  wire        cin,
    output wire [3:0]  sum,
    output wire        cout
);

    wire [1:0] sum_low;
    wire       carry_low;
    wire [1:0] sum_high0, sum_high1;
    wire       carry_high0, carry_high1;

    // Lower bits adder submodule
    lower_bits_adder lower_adder (
        .clk     (clk),
        .rst_n   (rst_n),
        .a       (a[1:0]),
        .b       (b[1:0]),
        .cin     (cin),
        .sum     (sum_low),
        .cout    (carry_low)
    );

    // Upper bits parallel adder submodule
    upper_bits_adder upper_adder (
        .clk         (clk),
        .rst_n       (rst_n),
        .a           (a[3:2]),
        .b           (b[3:2]),
        .sum_high0   (sum_high0),
        .sum_high1   (sum_high1),
        .carry_high0 (carry_high0),
        .carry_high1 (carry_high1)
    );

    // Carry select and output submodule
    carry_select_logic select_logic (
        .clk         (clk),
        .rst_n       (rst_n),
        .sum_low     (sum_low),
        .carry_low   (carry_low),
        .sum_high0   (sum_high0),
        .sum_high1   (sum_high1),
        .carry_high0 (carry_high0),
        .carry_high1 (carry_high1),
        .sum         (sum),
        .cout        (cout)
    );

endmodule

// Lower bits adder module
module lower_bits_adder(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  a,
    input  wire [1:0]  b,
    input  wire        cin,
    output reg  [1:0]  sum,
    output reg         cout
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum  <= 2'b0;
            cout <= 1'b0;
        end else begin
            {cout, sum} <= a + b + cin;
        end
    end

endmodule

// Upper bits parallel adder module
module upper_bits_adder(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  a,
    input  wire [1:0]  b,
    output reg  [1:0]  sum_high0,
    output reg  [1:0]  sum_high1,
    output reg         carry_high0,
    output reg         carry_high1
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_high0   <= 2'b0;
            sum_high1   <= 2'b0;
            carry_high0 <= 1'b0;
            carry_high1 <= 1'b0;
        end else begin
            {carry_high0, sum_high0} <= a + b + 1'b0;
            {carry_high1, sum_high1} <= a + b + 1'b1;
        end
    end

endmodule

// Carry select logic module
module carry_select_logic(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  sum_low,
    input  wire        carry_low,
    input  wire [1:0]  sum_high0,
    input  wire [1:0]  sum_high1,
    input  wire        carry_high0,
    input  wire        carry_high1,
    output reg  [3:0]  sum,
    output reg         cout
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum  <= 4'b0;
            cout <= 1'b0;
        end else begin
            sum  <= {carry_low ? sum_high1 : sum_high0, sum_low};
            cout <= carry_low ? carry_high1 : carry_high0;
        end
    end

endmodule