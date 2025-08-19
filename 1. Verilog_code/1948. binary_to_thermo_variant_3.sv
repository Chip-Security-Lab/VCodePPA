//SystemVerilog
// Top-level structured binary to thermometer code converter with pipelined data path
module binary_to_thermo #(
    parameter BIN_WIDTH = 3
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire [BIN_WIDTH-1:0]         bin_in,
    output reg  [(1<<BIN_WIDTH)-1:0]    thermo_out
);

    // Stage 1: Input Latch
    reg [BIN_WIDTH-1:0] bin_in_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_in_stage1 <= {BIN_WIDTH{1'b0}};
        else
            bin_in_stage1 <= bin_in;
    end

    // Stage 2: Thermometer Code Generation (combinational)
    wire [(1<<BIN_WIDTH)-1:0] thermo_code_stage2;
    genvar idx;
    generate
        for (idx = 0; idx < (1<<BIN_WIDTH); idx = idx + 1) begin : THERMO_GEN
            assign thermo_code_stage2[idx] = (idx < bin_in_stage1) ? 1'b1 : 1'b0;
        end
    endgenerate

    // Stage 3: Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            thermo_out <= {((1<<BIN_WIDTH)){1'b0}};
        else
            thermo_out <= thermo_code_stage2;
    end

endmodule