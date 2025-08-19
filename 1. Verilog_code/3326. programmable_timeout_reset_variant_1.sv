//SystemVerilog
module programmable_timeout_reset #(
    parameter CLK_FREQ = 100000
)(
    input clk,
    input rst_n,
    input enable,
    input [31:0] timeout_ms,
    input timeout_trigger,
    input timeout_clear,
    output reg reset_out,
    output reg timeout_active
);

    // Pipeline stage 1: Calculate timeout_cycles
    reg [31:0] timeout_ms_reg;
    reg [31:0] clk_freq_div_reg;
    reg [31:0] timeout_cycles_stage1;
    reg [31:0] timeout_cycles_stage2;

    wire [31:0] wallace_product;

    wallace_multiplier_32x32 wallace_mul_inst (
        .a(timeout_ms_reg),
        .b(clk_freq_div_reg),
        .product(wallace_product)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_ms_reg         <= 32'd0;
            clk_freq_div_reg       <= 32'd0;
            timeout_cycles_stage1  <= 32'd0;
            timeout_cycles_stage2  <= 32'd0;
        end else begin
            timeout_ms_reg         <= timeout_ms;
            clk_freq_div_reg       <= CLK_FREQ / 1000;
            timeout_cycles_stage1  <= wallace_product;
            timeout_cycles_stage2  <= timeout_cycles_stage1;
        end
    end

    // Pipeline stage 2: FSM and counter
    reg [31:0] counter_reg;
    reg timeout_active_reg;
    reg reset_out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_reg          <= 32'd0;
            timeout_active_reg   <= 1'b0;
            reset_out_reg        <= 1'b0;
        end else if (!enable) begin
            counter_reg          <= 32'd0;
            timeout_active_reg   <= 1'b0;
            reset_out_reg        <= 1'b0;
        end else if (timeout_clear) begin
            counter_reg          <= 32'd0;
            timeout_active_reg   <= 1'b0;
            reset_out_reg        <= 1'b0;
        end else if (timeout_trigger && !timeout_active_reg) begin
            counter_reg          <= 32'd1;
            timeout_active_reg   <= 1'b1;
            reset_out_reg        <= 1'b0;
        end else if (timeout_active_reg) begin
            if (counter_reg < timeout_cycles_stage2) begin
                counter_reg      <= counter_reg + 32'd1;
                reset_out_reg    <= 1'b0;
            end else begin
                reset_out_reg    <= 1'b1;
            end
        end
    end

    // Pipeline stage 3: Output registers to align with pipeline latency
    reg timeout_active_out_reg;
    reg reset_out_out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_active_out_reg <= 1'b0;
            reset_out_out_reg      <= 1'b0;
        end else begin
            timeout_active_out_reg <= timeout_active_reg;
            reset_out_out_reg      <= reset_out_reg;
        end
    end

    // Output assignments
    always @(*) begin
        timeout_active = timeout_active_out_reg;
        reset_out      = reset_out_out_reg;
    end

endmodule

// Wallace Tree 32x32 Multiplier Module
module wallace_multiplier_32x32(
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] product
);
    wire [63:0] mult_result;

    wallace_tree_32x32_core wallace_core (
        .a(a),
        .b(b),
        .product(mult_result)
    );

    assign product = mult_result[31:0];

endmodule

// Wallace Tree Core for 32x32 Multiplication
module wallace_tree_32x32_core(
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] product
);
    wire [31:0] pp[31:0];
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_partial_products
            assign pp[i] = b[i] ? a : 32'd0;
        end
    endgenerate

    // Stage 1: Sum reduction (Wallace tree)
    wire [63:0] s1 [15:0], c1 [15:0];
    wire [63:0] s2 [7:0],  c2 [7:0];
    wire [63:0] s3 [3:0],  c3 [3:0];
    wire [63:0] s4 [1:0],  c4 [1:0];
    wire [63:0] s5, c5;

    // Extend partial products to 64 bits and shift accordingly
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_pp_shift
            assign s1[i/2][63:0] = ((i%2)==0) ? {32'd0, pp[i]} : {32'd0, 32'd0};
            assign c1[i/2][63:0] = ((i%2)==1) ? {pp[i], 32'd0} : {32'd0, 32'd0};
        end
    endgenerate

    // Stage 2: Carry-Save Adder tree reductions
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_stage2
            assign {c2[i], s2[i]} = s1[2*i] + c1[2*i] + s1[2*i+1] + c1[2*i+1];
        end
    endgenerate

    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_stage3
            assign {c3[i], s3[i]} = s2[2*i] + c2[2*i] + s2[2*i+1] + c2[2*i+1];
        end
    endgenerate

    generate
        for (i = 0; i < 2; i = i + 1) begin : gen_stage4
            assign {c4[i], s4[i]} = s3[2*i] + c3[2*i] + s3[2*i+1] + c3[2*i+1];
        end
    endgenerate

    assign {c5, s5} = s4[0] + c4[0] + s4[1] + c4[1];

    // Final addition
    assign product = s5 + c5;

endmodule