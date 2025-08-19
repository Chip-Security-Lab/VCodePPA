//SystemVerilog
module gamma_corr #(
    parameter DEPTH = 256
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [7:0]   in_data,
    input  wire         in_valid,
    output wire [7:0]   out_data,
    output wire         out_valid
);

// -----------------------------------------------------------------------------
// LUT Stage: Lookup table registers (Read Only)
// -----------------------------------------------------------------------------
reg [7:0] gamma_lut [0:DEPTH-1];

initial begin
    $readmemh("gamma_lut.hex", gamma_lut);
end

// -----------------------------------------------------------------------------
// Stage 1: Input Register (Captures input data and valid)
// -----------------------------------------------------------------------------
reg [7:0] reg_in_data;
reg       reg_in_valid;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg_in_data  <= 8'd0;
        reg_in_valid <= 1'b0;
    end else begin
        reg_in_data  <= in_data;
        reg_in_valid <= in_valid;
    end
end

// -----------------------------------------------------------------------------
// Stage 2: LUT Access (Output of LUT, registered)
// Optimized: Use single enable and range check for LUT access
// -----------------------------------------------------------------------------
reg [7:0] reg_lut_data;
reg       reg_lut_valid;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg_lut_data  <= 8'd0;
        reg_lut_valid <= 1'b0;
    end else begin
        if (reg_in_valid && (reg_in_data < DEPTH[7:0])) begin
            reg_lut_data  <= gamma_lut[reg_in_data];
            reg_lut_valid <= 1'b1;
        end else begin
            reg_lut_data  <= 8'd0;
            reg_lut_valid <= 1'b0;
        end
    end
end

// -----------------------------------------------------------------------------
// Stage 3: Fanout Buffering for reg_lut_data
// Optimized: Remove unnecessary duplicated buffers
// -----------------------------------------------------------------------------
reg [7:0] buf_lut_data;
reg       buf_lut_valid;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        buf_lut_data  <= 8'd0;
        buf_lut_valid <= 1'b0;
    end else begin
        buf_lut_data  <= reg_lut_data;
        buf_lut_valid <= reg_lut_valid;
    end
end

// -----------------------------------------------------------------------------
// Output Assignment (using optimized buffered outputs)
// -----------------------------------------------------------------------------
assign out_data  = buf_lut_data;
assign out_valid = buf_lut_valid;

endmodule