//SystemVerilog
module conditional_regfile #(
    parameter WIDTH = 32,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [WIDTH-1:0]       wr_data,
    input  wire [WIDTH-1:0]       wr_mask,
    input  wire                   wr_condition,
    input  wire [ADDR_WIDTH-1:0]  rd_addr,
    output wire [WIDTH-1:0]       rd_data
);

    reg [WIDTH-1:0] memory [0:DEPTH-1];
    wire [WIDTH-1:0] masked_data;
    wire [WIDTH-1:0] preserved_data;
    wire [WIDTH-1:0] new_data;
    wire write_enable;

    // Optimized write enable logic
    assign write_enable = wr_en & wr_condition;

    // Pre-compute masked and preserved data
    assign masked_data = (memory[wr_addr] - wr_data) & wr_mask;
    assign preserved_data = memory[wr_addr] & ~wr_mask;
    assign new_data = masked_data | preserved_data;

    // Combinational read
    assign rd_data = memory[rd_addr];

    // Optimized write logic
    always @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < DEPTH; i++) begin
                memory[i] <= {WIDTH{1'b0}};
            end
        end
        else if (write_enable) begin
            memory[wr_addr] <= new_data;
        end
    end

endmodule