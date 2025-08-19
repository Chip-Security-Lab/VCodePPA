//SystemVerilog
module CRC16_Shifter_Pipelined #(
    parameter POLY = 16'h8005
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        serial_in,
    input  wire        valid_in,
    output wire [15:0] crc_out,
    output wire        valid_out
);

    // Stage 1: Prepare input and previous CRC
    reg         serial_in_stage1;
    reg [15:0]  crc_stage1;
    reg         valid_stage1;

    pipeline_reg #(
        .WIDTH(18),  // 16 for crc, 1 for serial_in, 1 for valid
        .RESET_VAL({16'hFFFF, 1'b0, 1'b0})
    ) u_stage1 (
        .clk    (clk),
        .rst    (rst),
        .din    ({crc_out, serial_in, valid_in}),
        .en     (valid_in),
        .dout   ({crc_stage1, serial_in_stage1, valid_stage1})
    );

    // Stage 2: Compute CRC next value
    wire [15:0] crc_next_stage2;
    wire        crc_xor_bit;

    assign crc_xor_bit = crc_stage1[15] ^ serial_in_stage1;
    assign crc_next_stage2 = {crc_stage1[14:0], 1'b0} ^ (POLY & {16{crc_xor_bit}});

    reg [15:0]  crc_stage2;
    reg         valid_stage2;

    pipeline_reg #(
        .WIDTH(17), // 16 for crc, 1 for valid
        .RESET_VAL({16'hFFFF, 1'b0})
    ) u_stage2 (
        .clk    (clk),
        .rst    (rst),
        .din    ({crc_next_stage2, valid_stage1}),
        .en     (valid_stage1),
        .dout   ({crc_stage2, valid_stage2})
    );

    // Output register
    reg [15:0]  crc_stage3;
    reg         valid_stage3;

    pipeline_reg #(
        .WIDTH(17), // 16 for crc, 1 for valid
        .RESET_VAL({16'hFFFF, 1'b0})
    ) u_stage3 (
        .clk    (clk),
        .rst    (rst),
        .din    ({crc_stage2, valid_stage2}),
        .en     (valid_stage2),
        .dout   ({crc_stage3, valid_stage3})
    );

    assign crc_out  = crc_stage3;
    assign valid_out = valid_stage3;

endmodule

// Parameterized reusable pipeline register module
module pipeline_reg #(
    parameter WIDTH = 8,
    parameter RESET_VAL = {8{1'b0}}
)(
    input  wire               clk,
    input  wire               rst,
    input  wire [WIDTH-1:0]   din,
    input  wire               en,
    output reg  [WIDTH-1:0]   dout
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= RESET_VAL;
        end else if (en) begin
            dout <= din;
        end
    end
endmodule