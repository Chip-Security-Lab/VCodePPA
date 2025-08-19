//SystemVerilog
// Top-level module: Hierarchical xorshift random number generator
module xorshift_rng (
    input wire clk,
    input wire rst_n,
    output wire [31:0] rand_num
);

    // Internal register to hold the current random number
    reg [31:0] rand_num_reg;
    wire [31:0] xorshift_stage1_out;
    wire [31:0] xorshift_stage2_out;
    wire [31:0] xorshift_stage3_out;

    // Stage 1: rand_num_reg ^ (rand_num_reg << 13)
    xorshift_stage1 u_stage1 (
        .in_data(rand_num_reg),
        .out_data(xorshift_stage1_out)
    );

    // Stage 2: stage1_out ^ (stage1_out >> 17)
    xorshift_stage2 u_stage2 (
        .in_data(xorshift_stage1_out),
        .out_data(xorshift_stage2_out)
    );

    // Stage 3: stage2_out ^ (stage2_out << 5)
    xorshift_stage3 u_stage3 (
        .in_data(xorshift_stage2_out),
        .out_data(xorshift_stage3_out)
    );

    // Sequential logic for updating random number
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rand_num_reg <= 32'h1;
        else
            rand_num_reg <= xorshift_stage3_out;
    end

    assign rand_num = rand_num_reg;

endmodule

// ------------------------------------------------------------------------
// xorshift_stage1: Performs XORSHIFT left operation
// Function: out_data = in_data ^ (in_data << 13)
// ------------------------------------------------------------------------
module xorshift_stage1 (
    input  wire [31:0] in_data,
    output wire [31:0] out_data
);
    assign out_data = in_data ^ (in_data << 13);
endmodule

// ------------------------------------------------------------------------
// xorshift_stage2: Performs XORSHIFT right operation
// Function: out_data = in_data ^ (in_data >> 17)
// ------------------------------------------------------------------------
module xorshift_stage2 (
    input  wire [31:0] in_data,
    output wire [31:0] out_data
);
    assign out_data = in_data ^ (in_data >> 17);
endmodule

// ------------------------------------------------------------------------
// xorshift_stage3: Performs XORSHIFT left operation
// Function: out_data = in_data ^ (in_data << 5)
// ------------------------------------------------------------------------
module xorshift_stage3 (
    input  wire [31:0] in_data,
    output wire [31:0] out_data
);
    assign out_data = in_data ^ (in_data << 5);
endmodule