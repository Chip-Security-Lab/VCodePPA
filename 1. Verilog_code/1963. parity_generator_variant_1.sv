//SystemVerilog
module parity_generator #(
    parameter DATA_WIDTH = 8,
    parameter EVEN_PARITY = 1  // 1: even parity, 0: odd parity
)(
    input                   clk,
    input                   rst_n,
    input  [DATA_WIDTH-1:0] data_in,
    output                  parity_out
);

    // Stage 1: Input Register Stage
    reg [DATA_WIDTH-1:0] data_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_stage1 <= {DATA_WIDTH{1'b0}};
        else
            data_stage1 <= data_in;
    end

    // Stage 2: Parity Lookup Stage
    wire parity_lut_out;
    parity_lut8 u_parity_lut8 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_stage1[7:0]),
        .parity_out(parity_lut_out)
    );

    // Stage 3: Parity Post-Processing Stage
    reg parity_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            parity_stage2 <= 1'b0;
        else
            parity_stage2 <= EVEN_PARITY ? parity_lut_out : ~parity_lut_out;
    end

    assign parity_out = parity_stage2;

endmodule

// 8-bit Parity Lookup Table with Registered Output
module parity_lut8 (
    input        clk,
    input        rst_n,
    input  [7:0] data_in,
    output       parity_out
);

    // Stage 1: Lookup Table Memory
    reg parity_lut [0:255];
    initial begin
        integer i;
        for (i = 0; i < 256; i = i + 1) begin
            parity_lut[i] = ^i;
        end
    end

    // Stage 2: Registered Lookup Result
    reg parity_lookup_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            parity_lookup_stage1 <= 1'b0;
        else
            parity_lookup_stage1 <= parity_lut[data_in];
    end

    assign parity_out = parity_lookup_stage1;

endmodule