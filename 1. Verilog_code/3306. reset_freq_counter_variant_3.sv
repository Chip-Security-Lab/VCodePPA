//SystemVerilog
module reset_freq_counter(
    input clk,
    input rst_n,
    input ext_rst_n,
    input wdt_rst_n,
    output reg [7:0] ext_rst_count,
    output reg [7:0] wdt_rst_count,
    output reg any_reset
);

//------------------------------------------------------------------------------
// Registers to store previous state of reset signals
//------------------------------------------------------------------------------
reg ext_rst_n_prev;
reg wdt_rst_n_prev;

//------------------------------------------------------------------------------
// ext_rst_n_prev register update
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ext_rst_n_prev <= 1'b1;
    else
        ext_rst_n_prev <= ext_rst_n;
end

//------------------------------------------------------------------------------
// wdt_rst_n_prev register update
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        wdt_rst_n_prev <= 1'b1;
    else
        wdt_rst_n_prev <= wdt_rst_n;
end

//------------------------------------------------------------------------------
// ext_rst_count register update
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ext_rst_count <= 8'h00;
    else if (ext_rst_n_prev && !ext_rst_n)
        ext_rst_count <= ext_rst_count + 1'b1;
end

//------------------------------------------------------------------------------
// wdt_rst_count register update
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        wdt_rst_count <= 8'h00;
    else if (wdt_rst_n_prev && !wdt_rst_n)
        wdt_rst_count <= wdt_rst_count + 1'b1;
end

//------------------------------------------------------------------------------
// any_reset combinational logic
//------------------------------------------------------------------------------
reg any_reset_next;
always @(*) begin
    any_reset_next = (!ext_rst_n) || (!wdt_rst_n);
end

//------------------------------------------------------------------------------
// any_reset register update
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        any_reset <= 1'b0;
    else
        any_reset <= any_reset_next;
end

endmodule