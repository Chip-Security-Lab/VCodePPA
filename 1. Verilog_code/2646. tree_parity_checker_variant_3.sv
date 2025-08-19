//SystemVerilog
module tree_parity_checker (
    input [31:0] data,
    output parity
);
    wire [15:0] stage1_out;
    wire [7:0]  stage2_out;
    wire [3:0]  stage3_out;
    wire [1:0]  stage4_out;

    // Stage 1: 32-bit to 16-bit reduction
    stage1_reducer stage1_inst (
        .data_in(data),
        .data_out(stage1_out)
    );

    // Stage 2: 16-bit to 8-bit reduction
    stage2_reducer stage2_inst (
        .data_in(stage1_out),
        .data_out(stage2_out)
    );

    // Stage 3: 8-bit to 4-bit reduction
    stage3_reducer stage3_inst (
        .data_in(stage2_out),
        .data_out(stage3_out)
    );

    // Stage 4: 4-bit to 2-bit reduction
    stage4_reducer stage4_inst (
        .data_in(stage3_out),
        .data_out(stage4_out)
    );

    // Final stage: 2-bit to 1-bit reduction
    final_reducer final_inst (
        .data_in(stage4_out),
        .parity(parity)
    );
endmodule

// Stage 1: 32-bit to 16-bit reduction module
module stage1_reducer (
    input [31:0] data_in,
    output [15:0] data_out
);
    assign data_out = data_in[31:16] ^ data_in[15:0];
endmodule

// Stage 2: 16-bit to 8-bit reduction module
module stage2_reducer (
    input [15:0] data_in,
    output [7:0] data_out
);
    assign data_out = data_in[15:8] ^ data_in[7:0];
endmodule

// Stage 3: 8-bit to 4-bit reduction module
module stage3_reducer (
    input [7:0] data_in,
    output [3:0] data_out
);
    assign data_out = data_in[7:4] ^ data_in[3:0];
endmodule

// Stage 4: 4-bit to 2-bit reduction module
module stage4_reducer (
    input [3:0] data_in,
    output [1:0] data_out
);
    assign data_out = data_in[3:2] ^ data_in[1:0];
endmodule

// Final stage: 2-bit to 1-bit reduction module
module final_reducer (
    input [1:0] data_in,
    output parity
);
    assign parity = data_in[1] ^ data_in[0];
endmodule