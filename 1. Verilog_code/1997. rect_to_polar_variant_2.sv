//SystemVerilog
module rect_to_polar #(parameter WIDTH=16, ITERATIONS=8)(
    input wire signed [WIDTH-1:0] x_in,
    input wire signed [WIDTH-1:0] y_in,
    output reg [WIDTH-1:0] magnitude,
    output reg [WIDTH-1:0] angle
);

    // Internal signals for datapath
    reg signed [WIDTH-1:0] x_current;
    reg signed [WIDTH-1:0] y_current;
    reg signed [WIDTH-1:0] x_next;
    reg signed [WIDTH-1:0] y_next;
    reg [WIDTH-1:0] z_current;
    reg [WIDTH-1:0] z_next;

    // Temporary variables for iteration
    reg signed [WIDTH-1:0] x_temp;
    reg signed [WIDTH-1:0] y_temp;

    // Lookup table for arctangent values
    reg signed [WIDTH-1:0] atan_table [0:ITERATIONS-1];

    // Barrel shifter outputs
    reg signed [WIDTH-1:0] barrel_shifted_y;
    reg signed [WIDTH-1:0] barrel_shifted_x_temp;

    // Iteration index
    integer i;

    // Function: Barrel shifter (arithmetic right shift)
    function automatic signed [WIDTH-1:0] barrel_shifter_arith;
        input signed [WIDTH-1:0] value;
        input [4:0] shift_amt;
        integer j;
        reg signed [WIDTH-1:0] stage [0:4];
    begin
        stage[0] = value;
        stage[1] = shift_amt[0] ? (stage[0] >>> 1) : stage[0];
        stage[2] = shift_amt[1] ? (stage[1] >>> 2) : stage[1];
        stage[3] = shift_amt[2] ? (stage[2] >>> 4) : stage[2];
        stage[4] = shift_amt[3] ? (stage[3] >>> 8) : stage[3];
        barrel_shifter_arith = stage[4];
    end
    endfunction

    // Function: 5-bit parallel borrow adder (subtractor)
    function [WIDTH-1:0] subtractor_pba_5bit;
        input [WIDTH-1:0] minuend;
        input [WIDTH-1:0] subtrahend;
        reg [4:0] generate_borrow;
        reg [4:0] propagate_borrow;
        reg [5:0] borrow;
        integer k;
        reg [WIDTH-1:0] diff;
    begin
        for (k = 0; k < 5; k = k + 1) begin
            generate_borrow[k] = (~minuend[k]) & subtrahend[k];
            propagate_borrow[k] = (~minuend[k]) | subtrahend[k];
        end
        borrow[0] = 1'b0;
        for (k = 0; k < 5; k = k + 1) begin
            borrow[k+1] = generate_borrow[k] | (propagate_borrow[k] & borrow[k]);
        end
        for (k = 0; k < 5; k = k + 1) begin
            diff[k] = minuend[k] ^ subtrahend[k] ^ borrow[k];
        end
        for (k = 5; k < WIDTH; k = k + 1) begin
            diff[k] = minuend[k] ^ subtrahend[k] ^ borrow[5];
        end
        subtractor_pba_5bit = diff;
    end
    endfunction

    // Function: 5-bit parallel carry adder
    function [WIDTH-1:0] adder_pba_5bit;
        input [WIDTH-1:0] a;
        input [WIDTH-1:0] b;
        reg [4:0] generate_carry;
        reg [4:0] propagate_carry;
        reg [5:0] carry;
        integer k;
        reg [WIDTH-1:0] sum;
    begin
        for (k = 0; k < 5; k = k + 1) begin
            generate_carry[k] = a[k] & b[k];
            propagate_carry[k] = a[k] | b[k];
        end
        carry[0] = 1'b0;
        for (k = 0; k < 5; k = k + 1) begin
            carry[k+1] = generate_carry[k] | (propagate_carry[k] & carry[k]);
        end
        for (k = 0; k < 5; k = k + 1) begin
            sum[k] = a[k] ^ b[k] ^ carry[k];
        end
        for (k = 5; k < WIDTH; k = k + 1) begin
            sum[k] = a[k] ^ b[k] ^ carry[5];
        end
        adder_pba_5bit = sum;
    end
    endfunction

    // Initialize arctangent lookup table
    initial begin : atan_table_init
        atan_table[0] = 32'd2949120;
        atan_table[1] = 32'd1740992;
        atan_table[2] = 32'd919872;
        atan_table[3] = 32'd466944;
        atan_table[4] = 32'd234368;
        atan_table[5] = 32'd117312;
        atan_table[6] = 32'd58688;
        atan_table[7] = 32'd29312;
    end

    // Always block 1: Input assignment
    always @* begin : input_assignment
        x_current = x_in;
        y_current = y_in;
        z_current = 0;
    end

    // Always block 2: Main CORDIC iteration loop
    always @* begin : cordic_iteration_loop
        x_next = x_current;
        y_next = y_current;
        z_next = z_current;
        for (i = 0; i < ITERATIONS; i = i + 1) begin
            x_temp = x_next;
            y_temp = y_next;
            barrel_shifted_y = barrel_shifter_arith(y_next, i[4:0]);
            barrel_shifted_x_temp = barrel_shifter_arith(x_temp, i[4:0]);
            if (y_next >= 0) begin
                x_next = adder_pba_5bit(x_next, barrel_shifted_y);
                y_next = subtractor_pba_5bit(y_next, barrel_shifted_x_temp);
                z_next = z_next + atan_table[i];
            end else begin
                x_next = subtractor_pba_5bit(x_next, barrel_shifted_y);
                y_next = adder_pba_5bit(y_next, barrel_shifted_x_temp);
                z_next = z_next - atan_table[i];
            end
        end
    end

    // Always block 3: Output assignment
    always @* begin : output_assignment
        magnitude = x_next;
        angle = z_next;
    end

endmodule