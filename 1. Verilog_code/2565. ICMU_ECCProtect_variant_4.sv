//SystemVerilog
module ICMU_ECCProtect #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH = 8
)(
    input clk,
    input rst_sync,
    input [DATA_WIDTH-1:0] data_in,
    input ctx_write,
    output [DATA_WIDTH-1:0] data_out,
    output reg ecc_error
);

    // Pipeline registers
    reg [DATA_WIDTH-1:0] data_pipe;
    reg [ECC_WIDTH-1:0] ecc_pipe;
    reg [DATA_WIDTH+ECC_WIDTH-1:0] mem_pipe;
    
    // Internal signals
    wire [ECC_WIDTH-1:0] ecc_gen;
    wire [ECC_WIDTH-1:0] ecc_check;
    reg [DATA_WIDTH+ECC_WIDTH-1:0] mem;

    // Stage 1: Data and ECC generation
    always @(posedge clk) begin
        if (rst_sync) begin
            data_pipe <= 0;
            ecc_pipe <= 0;
        end else begin
            data_pipe <= data_in;
            ecc_pipe <= ecc_gen;
        end
    end

    // ECC generation module
    ECC_Generator #(
        .DATA_WIDTH(DATA_WIDTH),
        .ECC_WIDTH(ECC_WIDTH)
    ) ecc_gen_inst (
        .data(data_in),
        .ecc(ecc_gen)
    );

    // Stage 2: Memory write and ECC check
    always @(posedge clk) begin
        if (rst_sync) begin
            mem <= 0;
            mem_pipe <= 0;
            ecc_error <= 0;
        end else begin
            if (ctx_write) begin
                mem <= {ecc_pipe, data_pipe};
                mem_pipe <= {ecc_pipe, data_pipe};
            end else begin
                mem_pipe <= mem;
            end
            ecc_error <= (ecc_check != 0);
        end
    end

    // ECC checking module
    ECC_Checker #(
        .DATA_WIDTH(DATA_WIDTH),
        .ECC_WIDTH(ECC_WIDTH)
    ) ecc_check_inst (
        .data(mem_pipe[DATA_WIDTH-1:0]),
        .stored_ecc(mem_pipe[DATA_WIDTH+ECC_WIDTH-1:DATA_WIDTH]),
        .ecc(ecc_check)
    );

    // Output assignment
    assign data_out = mem_pipe[DATA_WIDTH-1:0];

endmodule

module ECC_Generator #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data,
    output [ECC_WIDTH-1:0] ecc
);
    // Optimized ECC generation with reduced XOR depth
    wire [7:0] xor_stage1;
    wire [3:0] xor_stage2;
    wire [1:0] xor_stage3;
    
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_xor1
            assign xor_stage1[i] = ^data[i*8 +: 8];
        end
        for (i = 0; i < 4; i = i + 1) begin : gen_xor2
            assign xor_stage2[i] = xor_stage1[i*2] ^ xor_stage1[i*2+1];
        end
        for (i = 0; i < 2; i = i + 1) begin : gen_xor3
            assign xor_stage3[i] = xor_stage2[i*2] ^ xor_stage2[i*2+1];
        end
    endgenerate
    
    assign ecc = xor_stage3[0] ^ xor_stage3[1];
endmodule

module ECC_Checker #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data,
    input [ECC_WIDTH-1:0] stored_ecc,
    output [ECC_WIDTH-1:0] ecc
);
    wire [ECC_WIDTH-1:0] calc_ecc;
    
    // Reuse optimized ECC generation
    ECC_Generator #(
        .DATA_WIDTH(DATA_WIDTH),
        .ECC_WIDTH(ECC_WIDTH)
    ) ecc_gen_inst (
        .data(data),
        .ecc(calc_ecc)
    );
    
    assign ecc = calc_ecc ^ stored_ecc;
endmodule