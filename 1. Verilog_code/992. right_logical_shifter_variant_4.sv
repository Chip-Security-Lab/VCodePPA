//SystemVerilog
module right_logical_shifter #(
    parameter WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire enable,
    input wire [WIDTH-1:0] in_data,
    input wire [$clog2(WIDTH)-1:0] shift_amount,
    output reg [WIDTH-1:0] out_data
);

    // Internal register for input data
    reg [WIDTH-1:0] in_data_reg;
    reg [$clog2(WIDTH)-1:0] shift_amount_reg;
    reg enable_reg;

    // Register input signals at the first clock edge
    always @(posedge clock) begin
        if (reset) begin
            in_data_reg <= {WIDTH{1'b0}};
            shift_amount_reg <= {$clog2(WIDTH){1'b0}};
            enable_reg <= 1'b0;
        end else begin
            in_data_reg <= in_data;
            shift_amount_reg <= shift_amount;
            enable_reg <= enable;
        end
    end

    // Combinational logic for shifting
    wire [WIDTH-1:0] shifted_data_next;
    assign shifted_data_next = in_data_reg >> shift_amount_reg;

    // Output register block: Handles reset and output register update
    always @(posedge clock) begin
        if (reset)
            out_data <= {WIDTH{1'b0}};
        else if (enable_reg)
            out_data <= shifted_data_next;
    end

endmodule