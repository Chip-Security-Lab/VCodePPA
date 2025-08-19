//SystemVerilog
module adaptive_quant(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] data_in,
    input  wire [7:0]  quant_bits,
    output reg  [31:0] quant_out
);

    // Stage 1: Quantization scale calculation (pipelined)
    reg [31:0] scale_stage1;
    reg [31:0] data_stage1;
    reg [7:0]  bits_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scale_stage1 <= 32'd0;
            data_stage1  <= 32'd0;
            bits_stage1  <= 8'd0;
        end else begin
            scale_stage1 <= 32'd1 << quant_bits;
            data_stage1  <= data_in;
            bits_stage1  <= quant_bits;
        end
    end

    // Stage 2: Dadda multiplication (pipelined)
    reg [31:0] scale_stage2;
    reg [31:0] data_stage2;
    wire [63:0] mult_pdt_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scale_stage2 <= 32'd0;
            data_stage2  <= 32'd0;
        end else begin
            scale_stage2 <= scale_stage1;
            data_stage2  <= data_stage1;
        end
    end

    dadda_multiplier_32x32 dadda_mult_pipe (
        .clk(clk),
        .rst_n(rst_n),
        .a(data_stage1),
        .b(scale_stage1),
        .product(mult_pdt_stage2)
    );

    // Stage 3: Overflow detection and output assignment (pipelined)
    reg [31:0] data_stage3;
    reg [63:0] mult_pdt_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3     <= 32'd0;
            mult_pdt_stage3 <= 64'd0;
        end else begin
            data_stage3     <= data_stage2;
            mult_pdt_stage3 <= mult_pdt_stage2;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quant_out <= 32'd0;
        end else begin
            // Overflow detection logic, pipelined
            if (data_stage3[31] == 1'b0 && mult_pdt_stage3[63:31] != 33'd0)
                quant_out <= 32'h7FFFFFFF;
            else if (data_stage3[31] == 1'b1 && mult_pdt_stage3[63:31] != {33{1'b1}})
                quant_out <= 32'h80000000;
            else
                quant_out <= mult_pdt_stage3[31:0];
        end
    end

endmodule

// ===================== Structured Dadda Multiplier Top =====================
module dadda_multiplier_32x32(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [63:0] product
);

    // Stage 1: Partial Product Generation
    reg  [31:0] pp_reg [0:31];
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                pp_reg[i] <= 32'd0;
        end else begin
            for (i = 0; i < 32; i = i + 1)
                pp_reg[i] <= b[i] ? a : 32'd0;
        end
    end

    // Stage 2: Compress 32 to 17 rows
    wire [63:0] sum_17 [0:16];
    wire [63:0] carry_17 [0:16];
    dadda_stage32to17 dadda_s1 (
        .clk(clk),
        .rst_n(rst_n),
        .pp(pp_reg),
        .sum(sum_17),
        .carry(carry_17)
    );

    // Stage 3: Compress 17 to 9 rows
    wire [63:0] sum_9 [0:8];
    wire [63:0] carry_9 [0:8];
    dadda_stage17to9 dadda_s2 (
        .clk(clk),
        .rst_n(rst_n),
        .sum_in(sum_17),
        .carry_in(carry_17),
        .sum_out(sum_9),
        .carry_out(carry_9)
    );

    // Stage 4: Compress 9 to 5 rows
    wire [63:0] sum_5 [0:4];
    wire [63:0] carry_5 [0:4];
    dadda_stage9to5 dadda_s3 (
        .clk(clk),
        .rst_n(rst_n),
        .sum_in(sum_9),
        .carry_in(carry_9),
        .sum_out(sum_5),
        .carry_out(carry_5)
    );

    // Stage 5: Compress 5 to 3 rows
    wire [63:0] sum_3 [0:2];
    wire [63:0] carry_3 [0:2];
    dadda_stage5to3 dadda_s4 (
        .clk(clk),
        .rst_n(rst_n),
        .sum_in(sum_5),
        .carry_in(carry_5),
        .sum_out(sum_3),
        .carry_out(carry_3)
    );

    // Stage 6: Compress 3 to 2 rows
    wire [63:0] sum_2;
    wire [63:0] carry_2;
    dadda_stage3to2 dadda_final (
        .clk(clk),
        .rst_n(rst_n),
        .sum_in(sum_3),
        .carry_in(carry_3),
        .sum_out(sum_2),
        .carry_out(carry_2)
    );

    // Stage 7: Final Carry Propagate Adder (Registered Output)
    reg [63:0] product_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            product_reg <= 64'd0;
        else
            product_reg <= sum_2 + carry_2;
    end
    assign product = product_reg;

endmodule

// ===================== Dadda Compressor Stages =====================

// Stage 1: 32 to 17
module dadda_stage32to17(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] pp [0:31],
    output reg  [63:0] sum [0:16],
    output reg  [63:0] carry [0:16]
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 17; i = i + 1) begin
                sum[i]   <= 64'd0;
                carry[i] <= 64'd0;
            end
        end else begin
            for (i = 0; i < 17; i = i + 1) begin
                sum[i]   <= {32'd0, pp[2*i]};
                carry[i] <= {32'd0, pp[2*i+1]};
            end
        end
    end
endmodule

// Stage 2: 17 to 9
module dadda_stage17to9(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] sum_in [0:16],
    input  wire [63:0] carry_in [0:16],
    output reg  [63:0] sum_out [0:8],
    output reg  [63:0] carry_out [0:8]
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 9; i = i + 1) begin
                sum_out[i]   <= 64'd0;
                carry_out[i] <= 64'd0;
            end
        end else begin
            for (i = 0; i < 9; i = i + 1) begin
                sum_out[i]   <= sum_in[2*i] ^ carry_in[2*i];
                carry_out[i] <= sum_in[2*i+1] & carry_in[2*i+1];
            end
        end
    end
endmodule

// Stage 3: 9 to 5
module dadda_stage9to5(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] sum_in [0:8],
    input  wire [63:0] carry_in [0:8],
    output reg  [63:0] sum_out [0:4],
    output reg  [63:0] carry_out [0:4]
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 5; i = i + 1) begin
                sum_out[i]   <= 64'd0;
                carry_out[i] <= 64'd0;
            end
        end else begin
            for (i = 0; i < 5; i = i + 1) begin
                sum_out[i]   <= sum_in[2*i] ^ carry_in[2*i];
                carry_out[i] <= sum_in[2*i+1] & carry_in[2*i+1];
            end
        end
    end
endmodule

// Stage 4: 5 to 3
module dadda_stage5to3(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] sum_in [0:4],
    input  wire [63:0] carry_in [0:4],
    output reg  [63:0] sum_out [0:2],
    output reg  [63:0] carry_out [0:2]
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 3; i = i + 1) begin
                sum_out[i]   <= 64'd0;
                carry_out[i] <= 64'd0;
            end
        end else begin
            for (i = 0; i < 3; i = i + 1) begin
                sum_out[i]   <= sum_in[i] ^ carry_in[i];
                carry_out[i] <= sum_in[i+1] & carry_in[i+1];
            end
        end
    end
endmodule

// Stage 5: 3 to 2
module dadda_stage3to2(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] sum_in [0:2],
    input  wire [63:0] carry_in [0:2],
    output reg  [63:0] sum_out,
    output reg  [63:0] carry_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_out   <= 64'd0;
            carry_out <= 64'd0;
        end else begin
            sum_out   <= sum_in[0] ^ carry_in[0] ^ sum_in[1] ^ carry_in[1] ^ sum_in[2] ^ carry_in[2];
            carry_out <= (sum_in[0] & carry_in[0]) | (sum_in[1] & carry_in[1]) | (sum_in[2] & carry_in[2]);
        end
    end
endmodule