//SystemVerilog

module NeuralRecovery_Pipeline #(parameter W1=8'h2A, W2=8'hD3) (
    input clk,
    input rst_n,
    input valid_in,
    input [7:0] noisy,
    output reg valid_out,
    output reg [7:0] clean
);
    // Stage 1: Input Register
    reg [7:0] noisy_stage1;
    reg valid_stage1;

    // Stage 2: Hidden Layer Multiplication
    reg [15:0] mult_a_stage2, mult_b_stage2;
    reg valid_stage2;

    wire [15:0] hidden_stage2_result;
    wire hidden_stage2_valid;

    // Stage 3: Output Layer Multiplication
    reg [15:0] mult_a_stage3, mult_b_stage3;
    reg valid_stage3;

    wire [15:0] output_layer_stage3_result;
    wire output_layer_stage3_valid;

    // Stage 4: Output Register and Threshold
    reg [15:0] output_layer_stage4;
    reg valid_stage4;

    // Stage 1: Latch input and valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            noisy_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            noisy_stage1 <= noisy;
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2: Prepare operands for hidden layer multiplication
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_a_stage2 <= 16'd0;
            mult_b_stage2 <= 16'd0;
            valid_stage2  <= 1'b0;
        end else begin
            mult_a_stage2 <= {8'b0, noisy_stage1};
            mult_b_stage2 <= {8'b0, W1};
            valid_stage2  <= valid_stage1;
        end
    end

    // Stage 2: Hidden layer multiplier (pipelined)
    WallaceTreeMultiplier16_Pipeline hidden_mult_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_stage2),
        .a(mult_a_stage2),
        .b(mult_b_stage2),
        .valid_out(hidden_stage2_valid),
        .product(hidden_stage2_result)
    );

    // Stage 3: Prepare operands for output layer multiplication
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_a_stage3 <= 16'd0;
            mult_b_stage3 <= 16'd0;
            valid_stage3  <= 1'b0;
        end else begin
            mult_a_stage3 <= hidden_stage2_result;
            mult_b_stage3 <= {8'b0, W2};
            valid_stage3  <= hidden_stage2_valid;
        end
    end

    // Stage 3: Output layer multiplier (pipelined)
    WallaceTreeMultiplier16_Pipeline output_mult_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_stage3),
        .a(mult_a_stage3),
        .b(mult_b_stage3),
        .valid_out(output_layer_stage3_valid),
        .product(output_layer_stage3_result)
    );

    // Stage 4: Latch output layer result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_layer_stage4 <= 16'd0;
            valid_stage4        <= 1'b0;
        end else begin
            output_layer_stage4 <= output_layer_stage3_result;
            valid_stage4        <= output_layer_stage3_valid;
        end
    end

    // Stage 5: Thresholding & Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean     <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            if (valid_stage4) begin
                clean     <= (output_layer_stage4[15:8] > 8'h80) ? 8'hFF : 8'h00;
                valid_out <= 1'b1;
            end else begin
                clean     <= 8'd0;
                valid_out <= 1'b0;
            end
        end
    end
endmodule

// 2-stage pipelined Wallace Tree 16x16 Multiplier
module WallaceTreeMultiplier16_Pipeline (
    input clk,
    input rst_n,
    input valid_in,
    input  [15:0] a,
    input  [15:0] b,
    output reg valid_out,
    output reg [15:0] product
);
    // Stage 1: Partial Product Generation and First Reduction Layer
    reg [15:0] a_stage1, b_stage1;
    reg valid_stage1;

    wire [31:0] partial_products [15:0];
    genvar i;

    // Partial products
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_partial_products
            assign partial_products[i] = b_stage1[i] ? (a_stage1 << i) : 32'b0;
        end
    endgenerate

    // Wallace tree reduction: first layer
    wire [31:0] sum1 [7:0], carry1 [7:0];
    generate
        for (i = 0; i < 8; i = i + 1) begin : wallace_1
            assign {carry1[i], sum1[i]} = partial_products[2*i] + partial_products[2*i+1];
        end
    endgenerate

    // Wallace tree reduction: second layer
    wire [31:0] sum2 [3:0], carry2 [3:0];
    generate
        for (i = 0; i < 4; i = i + 1) begin : wallace_2
            assign {carry2[i], sum2[i]} = sum1[2*i] + sum1[2*i+1] + carry1[2*i] + carry1[2*i+1];
        end
    endgenerate

    // Stage 1 registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1      <= 16'd0;
            b_stage1      <= 16'd0;
            valid_stage1  <= 1'b0;
        end else begin
            a_stage1      <= a;
            b_stage1      <= b;
            valid_stage1  <= valid_in;
        end
    end

    // Stage 2: Final Reduction and Output Register
    wire [31:0] sum3 [1:0], carry3 [1:0];
    wire [31:0] sum4, carry4;
    wire [31:0] final_sum;

    generate
        for (i = 0; i < 2; i = i + 1) begin : wallace_3
            assign {carry3[i], sum3[i]} = sum2[2*i] + sum2[2*i+1] + carry2[2*i] + carry2[2*i+1];
        end
    endgenerate

    assign {carry4, sum4} = sum3[0] + sum3[1] + carry3[0] + carry3[1];
    assign final_sum = sum4 + carry4;

    // Stage 2 output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product   <= 16'd0;
            valid_out <= 1'b0;
        end else begin
            product   <= final_sum[15:0];
            valid_out <= valid_stage1;
        end
    end
endmodule