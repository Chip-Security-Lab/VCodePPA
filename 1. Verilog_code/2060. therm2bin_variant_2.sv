//SystemVerilog
// Top-level module: Hierarchical therm2bin thermometer-to-binary encoder
module therm2bin #(
    parameter THERM_WIDTH = 7,
    parameter BIN_WIDTH = $clog2(THERM_WIDTH+1)
) (
    input  wire [THERM_WIDTH-1:0] therm_in,
    output wire [BIN_WIDTH-1:0]   bin_out
);

    // Internal wire for sum
    wire [BIN_WIDTH-1:0] ones_count;

    // Submodule: Counts the number of 1's in the thermometer input
    ones_counter #(
        .THERM_WIDTH(THERM_WIDTH),
        .BIN_WIDTH(BIN_WIDTH)
    ) u_ones_counter (
        .data_in(therm_in),
        .ones_cnt(ones_count)
    );

    // Submodule: Registers the result (combinational in this case, but isolating for future PPA improvements)
    bin_register #(
        .BIN_WIDTH(BIN_WIDTH)
    ) u_bin_register (
        .data_in(ones_count),
        .data_out(bin_out)
    );

endmodule

// Submodule: ones_counter
// Counts the number of '1's in the thermometer input vector
module ones_counter #(
    parameter THERM_WIDTH = 7,
    parameter BIN_WIDTH = $clog2(THERM_WIDTH+1)
) (
    input  wire [THERM_WIDTH-1:0] data_in,
    output reg  [BIN_WIDTH-1:0]   ones_cnt
);

    reg [BIN_WIDTH-1:0] ones_cnt_next;
    integer idx;

    // Functional block: Calculate next value for ones_cnt
    // Counts the number of '1's in data_in and stores in ones_cnt_next
    always @(*) begin
        ones_cnt_next = {BIN_WIDTH{1'b0}};
        for (idx = 0; idx < THERM_WIDTH; idx = idx + 1) begin
            ones_cnt_next = ones_cnt_next + data_in[idx];
        end
    end

    // Functional block: Assign calculated value to output register
    always @(*) begin
        ones_cnt = ones_cnt_next;
    end

endmodule

// Submodule: bin_register
// Passes the count to output; can be replaced by a register for pipelining/PPA improvement
module bin_register #(
    parameter BIN_WIDTH = 3
) (
    input  wire [BIN_WIDTH-1:0] data_in,
    output wire [BIN_WIDTH-1:0] data_out
);
    // Currently combinational, can be changed to sequential for timing/area/power tradeoff
    assign data_out = data_in;
endmodule