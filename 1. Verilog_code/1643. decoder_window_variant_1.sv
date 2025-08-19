//SystemVerilog
module decoder_window #(
    parameter AW = 16
) (
    input  wire              clk,
    input  wire [AW-1:0]     base_addr,
    input  wire [AW-1:0]     window_size,
    input  wire [AW-1:0]     addr_in,
    output reg               valid
);

    // Pipeline stage 1: Address range calculation
    reg [AW-1:0] upper_bound_reg;
    reg          in_range_reg;

    // Pipeline stage 2: Range comparison
    reg          valid_reg;

    // Stage 1: Calculate upper bound and initial range check
    always @(posedge clk) begin
        upper_bound_reg <= base_addr + window_size;
        in_range_reg    <= (addr_in >= base_addr) && (addr_in < upper_bound_reg);
    end

    // Stage 2: Final validation
    always @(posedge clk) begin
        valid_reg <= in_range_reg;
    end

    // Output assignment
    always @(posedge clk) begin
        valid <= valid_reg;
    end

endmodule