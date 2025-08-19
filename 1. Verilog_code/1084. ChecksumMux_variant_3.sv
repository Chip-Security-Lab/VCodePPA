//SystemVerilog
// Top-level module: ChecksumMuxHier
module ChecksumMuxHier #(parameter DW=8) (
    input wire clk,
    input wire [3:0][DW-1:0] din,
    input wire [1:0] sel,
    output reg [DW+3:0] out
);

    wire [DW-1:0] muxed_data;
    wire [1:0] sel_delayed;
    wire [DW-1:0] data_delayed;
    wire [DW+3:0] out_next;

    // Move register after mux logic to improve timing from din/sel to FF
    DataCombiner #(.DW(DW)) u_data_combiner (
        .din(din),
        .sel(sel),
        .data_comb(muxed_data),
        .sel_comb(sel)
    );

    // Register group: data and sel after combination
    DataSelReg #(.DW(DW)) u_data_sel_reg (
        .clk(clk),
        .data_in(muxed_data),
        .sel_in(sel),
        .sel_reg(sel_delayed),
        .data_reg(data_delayed)
    );

    // Checksum and output logic
    ChecksumOutput #(.DW(DW)) u_checksum_output (
        .clk(clk),
        .data_comb(data_delayed),
        .sel_comb(sel_delayed),
        .out_next(out_next)
    );

    // Output register
    always @(posedge clk) begin
        out <= out_next;
    end

endmodule

//-----------------------------------------------------------------------------
// DataSelReg: Synchronizes sel and selected data input to registers
//-----------------------------------------------------------------------------
module DataSelReg #(parameter DW=8) (
    input wire clk,
    input wire [DW-1:0] data_in,
    input wire [1:0] sel_in,
    output reg [1:0] sel_reg,
    output reg [DW-1:0] data_reg
);
    always @(posedge clk) begin
        sel_reg <= sel_in;
        data_reg <= data_in;
    end
endmodule

//-----------------------------------------------------------------------------
// DataCombiner: Muxes data based on sel, passes through to next logic
//-----------------------------------------------------------------------------
module DataCombiner #(parameter DW=8) (
    input wire [3:0][DW-1:0] din,
    input wire [1:0] sel,
    output wire [DW-1:0] data_comb,
    output wire [1:0] sel_comb
);
    assign data_comb = din[sel];
    assign sel_comb = sel;
endmodule

//-----------------------------------------------------------------------------
// ChecksumOutput: Computes checksum and forms final output vector
//-----------------------------------------------------------------------------
module ChecksumOutput #(parameter DW=8) (
    input wire clk,
    input wire [DW-1:0] data_comb,
    input wire [1:0] sel_comb,
    output reg [DW+3:0] out_next
);
    always @(posedge clk) begin
        out_next <= {^data_comb, data_comb, sel_comb};
    end
endmodule