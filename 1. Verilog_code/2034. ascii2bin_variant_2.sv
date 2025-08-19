//SystemVerilog
// Top-level module: Structured ASCII to Binary Converter with Pipelined Dataflow
module ascii2bin (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  ascii_in,
    output wire [6:0]  bin_out
);

    // Pipeline Stage 1: Input Registering
    wire [7:0] ascii_stage1;
    ascii2bin_stage1_reg u_stage1_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .ascii_in   (ascii_in),
        .ascii_out  (ascii_stage1)
    );

    // Pipeline Stage 2: Parity Calculation and Data Registration
    wire        parity_stage2;
    wire [6:0]  ascii_stage2;
    ascii2bin_stage2 u_stage2 (
        .clk           (clk),
        .rst_n         (rst_n),
        .ascii_in      (ascii_stage1),
        .ascii_out     (ascii_stage2),
        .parity_out    (parity_stage2)
    );

    // Pipeline Stage 3: Output Selection
    ascii2bin_stage3 u_stage3 (
        .clk        (clk),
        .rst_n      (rst_n),
        .ascii_in   (ascii_stage2),
        .parity_in  (parity_stage2),
        .bin_out    (bin_out)
    );

endmodule

//-----------------------------------------------------------------------------
// Stage 1: Input Registering
//-----------------------------------------------------------------------------
module ascii2bin_stage1_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  ascii_in,
    output reg  [7:0]  ascii_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ascii_out <= 8'b0;
        else
            ascii_out <= ascii_in;
    end
endmodule

//-----------------------------------------------------------------------------
// Stage 2: Parity Calculation and Data Registration
//-----------------------------------------------------------------------------
module ascii2bin_stage2 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  ascii_in,
    output reg  [6:0]  ascii_out,
    output reg         parity_out
);
    wire parity_calc;
    assign parity_calc = ^ascii_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ascii_out  <= 7'b0;
            parity_out <= 1'b0;
        end else begin
            ascii_out  <= ascii_in[6:0];
            parity_out <= parity_calc;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Stage 3: Output Selection with Registered Output
//-----------------------------------------------------------------------------
module ascii2bin_stage3 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [6:0]  ascii_in,
    input  wire        parity_in,
    output reg  [6:0]  bin_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_out <= 7'b0;
        else
            bin_out <= parity_in ? ascii_in : 7'b0;
    end
endmodule