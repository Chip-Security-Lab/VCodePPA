//SystemVerilog
module float2int #(parameter INT_BITS = 32) (
    input wire clk, rst_n,
    input wire [31:0] float_in,  // IEEE-754 Single precision
    output reg signed [INT_BITS-1:0] int_out,
    output reg overflow
);

    // 1st stage buffer registers for input and key signals
    reg [31:0] float_in_buf1;
    reg [7:0] exp_field_buf1;
    reg [22:0] mantissa_field_buf1;
    reg sign_bit_buf1;

    // 2nd stage buffer registers for exp_field
    reg [7:0] exp_field_buf2;

    // 1st stage buffer for borrow_out
    reg borrow_out_buf1;

    // Buffer registers for a, b in subtractor
    reg [31:0] a_buf1, b_buf1;

    // 2nd stage buffer for a, b in subtractor (to further balance load)
    reg [31:0] a_buf2, b_buf2;

    // Internal signals
    wire [INT_BITS-1:0] shifted_value_wire;
    reg  [INT_BITS-1:0] shifted_value_buf1, shifted_value_buf2;
    wire [INT_BITS-1:0] diff_borrow_wire;
    reg  [INT_BITS-1:0] diff_borrow_buf1, diff_borrow_buf2;
    reg  [INT_BITS-1:0] neg_shifted_value_buf1, neg_shifted_value_buf2;

    // 1st stage: buffer float_in, exp_field, mantissa, sign_bit
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            float_in_buf1      <= 32'b0;
            exp_field_buf1     <= 8'b0;
            mantissa_field_buf1<= 23'b0;
            sign_bit_buf1      <= 1'b0;
        end else begin
            float_in_buf1      <= float_in;
            exp_field_buf1     <= float_in[30:23];
            mantissa_field_buf1<= float_in[22:0];
            sign_bit_buf1      <= float_in[31];
        end
    end

    // 2nd stage: buffer exp_field for wide fanout
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            exp_field_buf2 <= 8'b0;
        else
            exp_field_buf2 <= exp_field_buf1;
    end

    // Compute shifted_value (buffered)
    assign shifted_value_wire = {1'b1, mantissa_field_buf1} << (exp_field_buf2 - 127);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shifted_value_buf1 <= {INT_BITS{1'b0}};
        else
            shifted_value_buf1 <= shifted_value_wire;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shifted_value_buf2 <= {INT_BITS{1'b0}};
        else
            shifted_value_buf2 <= shifted_value_buf1;
    end

    // Buffer a, b for subtractor (a is always 0, but still buffer for timing/load balance)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_buf1 <= 32'b0;
            b_buf1 <= 32'b0;
        end else begin
            a_buf1 <= 32'b0;
            b_buf1 <= shifted_value_buf2;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_buf2 <= 32'b0;
            b_buf2 <= 32'b0;
        end else begin
            a_buf2 <= a_buf1;
            b_buf2 <= b_buf1;
        end
    end

    // Borrow-based subtractor (minuend - subtrahend) with buffered inputs
    borrow_subtractor_32 u_borrow_subtractor_32 (
        .a(a_buf2),
        .b(b_buf2),
        .diff(diff_borrow_wire),
        .borrow_out(borrow_out_wire)
    );

    // Buffer diff_borrow and borrow_out
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_borrow_buf1 <= {INT_BITS{1'b0}};
            borrow_out_buf1  <= 1'b0;
        end else begin
            diff_borrow_buf1 <= diff_borrow_wire;
            borrow_out_buf1  <= borrow_out_wire;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            diff_borrow_buf2 <= {INT_BITS{1'b0}};
        else
            diff_borrow_buf2 <= diff_borrow_buf1;
    end

    // Buffer neg_shifted_value for critical fanout
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            neg_shifted_value_buf1 <= {INT_BITS{1'b0}};
        else
            neg_shifted_value_buf1 <= diff_borrow_buf2;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            neg_shifted_value_buf2 <= {INT_BITS{1'b0}};
        else
            neg_shifted_value_buf2 <= neg_shifted_value_buf1;
    end

    // Output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= 0;
            overflow <= 1'b0;
        end else begin
            overflow <= (exp_field_buf2 > (127 + INT_BITS - 1));
            if (!overflow) begin
                if (sign_bit_buf1)
                    int_out <= neg_shifted_value_buf2;
                else
                    int_out <= shifted_value_buf2;
            end else begin
                int_out <= sign_bit_buf1 ? {1'b1, {(INT_BITS-1){1'b0}}} : {1'b0, {(INT_BITS-1){1'b1}}};
            end
        end
    end

endmodule

module borrow_subtractor_32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] diff,
    output wire borrow_out
);
    wire [31:0] borrow;

    assign {borrow[0], diff[0]} = {1'b0, a[0]} - {1'b0, b[0]};
    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : gen_borrow_sub
            assign {borrow[i], diff[i]} = {borrow[i-1], a[i]} - {1'b0, b[i]};
        end
    endgenerate
    assign borrow_out = borrow[31];
endmodule