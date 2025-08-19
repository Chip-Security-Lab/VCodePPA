//SystemVerilog
module float2fixed_pipeline #(parameter INT=4, FRAC=4) (
    input                    clk,
    input                    rst_n,
    input                    valid_in,
    input  [31:0]            float_in,
    output                   valid_out,
    output [INT+FRAC-1:0]    fixed_out
);

    // Stage 1: Input latch
    reg [31:0]                   float_in_stage1;
    reg                          valid_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            float_in_stage1 <= 32'd0;
            valid_stage1    <= 1'b0;
        end else begin
            float_in_stage1 <= float_in;
            valid_stage1    <= valid_in;
        end
    end

    // Stage 2: Prepare adder inputs
    reg [INT+FRAC-1:0]           adder_a_stage2;
    reg [INT+FRAC-1:0]           adder_b_stage2;
    reg                          adder_cin_stage2;
    reg                          valid_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            adder_a_stage2   <= {INT+FRAC{1'b0}};
            adder_b_stage2   <= {INT+FRAC{1'b0}};
            adder_cin_stage2 <= 1'b0;
            valid_stage2     <= 1'b0;
        end else begin
            adder_a_stage2   <= float_in_stage1[INT+FRAC-1:0];
            adder_b_stage2   <= {INT+FRAC{1'b0}};
            adder_cin_stage2 <= 1'b0;
            valid_stage2     <= valid_stage1;
        end
    end

    // Stage 3: Adder operation (carry_select_adder is pipelined internally)
    wire [INT+FRAC-1:0]          adder_sum_stage3;
    wire                         valid_stage3;
    carry_select_adder_pipeline #(.WIDTH(INT+FRAC)) u_carry_select_adder_pipeline (
        .clk         (clk),
        .rst_n       (rst_n),
        .a_in        (adder_a_stage2),
        .b_in        (adder_b_stage2),
        .cin_in      (adder_cin_stage2),
        .valid_in    (valid_stage2),
        .sum_out     (adder_sum_stage3),
        .valid_out   (valid_stage3)
    );

    // Stage 4: Output latch
    reg [INT+FRAC-1:0]           fixed_out_stage4;
    reg                          valid_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fixed_out_stage4 <= {INT+FRAC{1'b0}};
            valid_stage4     <= 1'b0;
        end else begin
            fixed_out_stage4 <= adder_sum_stage3;
            valid_stage4     <= valid_stage3;
        end
    end

    assign fixed_out = fixed_out_stage4;
    assign valid_out = valid_stage4;

endmodule

module carry_select_adder_pipeline #(parameter WIDTH=8, parameter BLOCK_SIZE=4) (
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      a_in,
    input  [WIDTH-1:0]      b_in,
    input                   cin_in,
    input                   valid_in,
    output [WIDTH-1:0]      sum_out,
    output                  valid_out
);
    // Pipeline stages for each block
    localparam NUM_BLOCKS = (WIDTH + BLOCK_SIZE - 1) / BLOCK_SIZE;

    // Stage 1: Input register
    reg  [WIDTH-1:0]        a_stage1;
    reg  [WIDTH-1:0]        b_stage1;
    reg                     cin_stage1;
    reg                     valid_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1    <= {WIDTH{1'b0}};
            b_stage1    <= {WIDTH{1'b0}};
            cin_stage1  <= 1'b0;
            valid_stage1<= 1'b0;
        end else begin
            a_stage1    <= a_in;
            b_stage1    <= b_in;
            cin_stage1  <= cin_in;
            valid_stage1<= valid_in;
        end
    end

    // Stage 2: Block 0 adder
    localparam integer LSB0 = 0;
    localparam integer MSB0 = ((1)*BLOCK_SIZE > WIDTH) ? WIDTH-1 : ((1)*BLOCK_SIZE-1);
    localparam integer BLK_WIDTH0 = MSB0-LSB0+1;

    wire [BLK_WIDTH0-1:0]    sum0_stage2;
    wire                     cout0_stage2;
    reg  [WIDTH-1:0]         sum_stage2;
    reg                      carry1_stage2;
    reg                      valid_stage2;

    ripple_carry_adder #(.WIDTH(BLK_WIDTH0)) u_ripple0 (
        .a   (a_stage1[MSB0:LSB0]),
        .b   (b_stage1[MSB0:LSB0]),
        .cin (cin_stage1),
        .sum (sum0_stage2),
        .cout(cout0_stage2)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage2      <= {WIDTH{1'b0}};
            carry1_stage2   <= 1'b0;
            valid_stage2    <= 1'b0;
        end else begin
            sum_stage2[MSB0:LSB0] <= sum0_stage2;
            carry1_stage2          <= cout0_stage2;
            valid_stage2           <= valid_stage1;
        end
    end

    // Stage 3: Block 1 adder
    generate
        if (NUM_BLOCKS > 1) begin : gen_block1
            localparam integer LSB1 = 1*BLOCK_SIZE;
            localparam integer MSB1 = ((2)*BLOCK_SIZE > WIDTH) ? WIDTH-1 : ((2)*BLOCK_SIZE-1);
            localparam integer BLK_WIDTH1 = MSB1-LSB1+1;

            wire [BLK_WIDTH1-1:0] sum1_stage3;
            wire                  cout1_stage3;
            reg  [WIDTH-1:0]      sum_stage3;
            reg                   carry2_stage3;
            reg                   valid_stage3;

            ripple_carry_adder #(.WIDTH(BLK_WIDTH1)) u_ripple1 (
                .a   (a_stage1[MSB1:LSB1]),
                .b   (b_stage1[MSB1:LSB1]),
                .cin (carry1_stage2),
                .sum (sum1_stage3),
                .cout(cout1_stage3)
            );

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    sum_stage3      <= {WIDTH{1'b0}};
                    carry2_stage3   <= 1'b0;
                    valid_stage3    <= 1'b0;
                end else begin
                    sum_stage3[MSB1:LSB1] <= sum1_stage3;
                    sum_stage3[MSB0:LSB0] <= sum_stage2[MSB0:LSB0];
                    carry2_stage3          <= cout1_stage3;
                    valid_stage3           <= valid_stage2;
                end
            end

            // Stage 4: Output (if more blocks, repeat similar pattern)
            reg [WIDTH-1:0] sum_stage_last;
            reg             valid_stage_last;
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    sum_stage_last   <= {WIDTH{1'b0}};
                    valid_stage_last <= 1'b0;
                end else begin
                    sum_stage_last   <= sum_stage3;
                    valid_stage_last <= valid_stage3;
                end
            end
            assign sum_out  = sum_stage_last;
            assign valid_out= valid_stage_last;

        end else begin : gen_block1_bypass
            assign sum_out   = sum_stage2;
            assign valid_out = valid_stage2;
        end
    endgenerate

endmodule

module ripple_carry_adder #(parameter WIDTH=4) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              cin,
    output [WIDTH-1:0] sum,
    output             cout
);
    wire [WIDTH:0] carry;
    assign carry[0] = cin;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_full_adder
            assign sum[i] = a[i] ^ b[i] ^ carry[i];
            assign carry[i+1] = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);
        end
    endgenerate
    assign cout = carry[WIDTH];
endmodule