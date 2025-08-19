//SystemVerilog
// Top-level module: sd2twos_pipeline
// Function: Converts signed-digit representation to two's complement using pipelined, structured datapath

module sd2twos_pipeline #(parameter W = 8)(
    input                   clk,
    input                   rst_n,
    input  [W-1:0]          sd_in,
    output reg [W:0]        twos_out
);

    // Stage 1: Input Register
    reg [W-1:0]             sd_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sd_stage1 <= {W{1'b0}};
        else
            sd_stage1 <= sd_in;
    end

    // Stage 2: Extend sd and msb in parallel (registered outputs)
    wire [W:0]              sd_ext_stage2;
    wire [W:0]              msb_ext_stage2;

    sd_extender #(.W(W)) u_sd_extender (
        .clk(clk),
        .rst_n(rst_n),
        .sd_in(sd_stage1),
        .sd_ext(sd_ext_stage2)
    );

    msb_extender #(.W(W)) u_msb_extender (
        .clk(clk),
        .rst_n(rst_n),
        .msb_in(sd_stage1[W-1]),
        .msb_ext(msb_ext_stage2)
    );

    // Stage 3: Vector addition (registered output)
    wire [W:0]              sum_stage3;

    vector_adder #(.W(W)) u_vector_adder (
        .clk(clk),
        .rst_n(rst_n),
        .a(sd_ext_stage2),
        .b(msb_ext_stage2),
        .sum(sum_stage3)
    );

    // Stage 4: Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            twos_out <= {(W+1){1'b0}};
        else
            twos_out <= sum_stage3;
    end

endmodule

// Submodule: sd_extender
// Function: Pipeline stage to extend sd to W+1 bits, output registered
module sd_extender #(parameter W = 8)(
    input                   clk,
    input                   rst_n,
    input  [W-1:0]          sd_in,
    output reg [W:0]        sd_ext
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sd_ext <= {(W+1){1'b0}};
        else
            sd_ext <= {1'b0, sd_in};
    end
endmodule

// Submodule: msb_extender
// Function: Pipeline stage to create MSB extension vector, output registered
module msb_extender #(parameter W = 8)(
    input                   clk,
    input                   rst_n,
    input                   msb_in,
    output reg [W:0]        msb_ext
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            msb_ext <= {(W+1){1'b0}};
        else
            msb_ext <= {msb_in, {W{1'b0}}};
    end
endmodule

// Submodule: vector_adder
// Function: Pipeline stage to add two W+1 bit vectors, output registered
module vector_adder #(parameter W = 8)(
    input                   clk,
    input                   rst_n,
    input  [W:0]            a,
    input  [W:0]            b,
    output reg [W:0]        sum
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sum <= {(W+1){1'b0}};
        else
            sum <= a + b;
    end
endmodule