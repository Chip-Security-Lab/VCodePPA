//SystemVerilog
// Top-level module: Hierarchical temperature compensation and recovery
module TempCompRecovery #(parameter WIDTH=12) (
    input clk,
    input [WIDTH-1:0] temp_sensor,
    input [WIDTH-1:0] raw_data,
    output [WIDTH-1:0] comp_data
);

    // Internal signals for submodule interconnection
    wire signed [WIDTH+2:0] temp_offset;
    wire [WIDTH-1:0] compensated_data;

    // Instantiate the temperature offset calculation module
    TempOffsetCalc #(.WIDTH(WIDTH)) u_temp_offset_calc (
        .clk(clk),
        .temp_sensor(temp_sensor),
        .offset(temp_offset)
    );

    // Instantiate the compensation adder module
    CompAdder #(.WIDTH(WIDTH)) u_comp_adder (
        .clk(clk),
        .raw_data(raw_data),
        .offset(temp_offset),
        .comp_data(compensated_data)
    );

    // Output assignment
    assign comp_data = compensated_data;

endmodule

// -----------------------------------------------------------------------------
// Submodule: TempOffsetCalc
// Function: Calculates signed temperature offset based on sensor input
// -----------------------------------------------------------------------------
module TempOffsetCalc #(parameter WIDTH=12) (
    input clk,
    input [WIDTH-1:0] temp_sensor,
    output reg signed [WIDTH+2:0] offset
);
    // Offset calculation: (temp_sensor - 2048) * 3
    always @(posedge clk) begin
        offset <= (temp_sensor - 12'd2048) * 3;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: CompAdder
// Function: Adds calculated offset to raw data, producing compensated output
// -----------------------------------------------------------------------------
module CompAdder #(parameter WIDTH=12) (
    input clk,
    input [WIDTH-1:0] raw_data,
    input signed [WIDTH+2:0] offset,
    output reg [WIDTH-1:0] comp_data
);
    // Compensation: Add offset (properly shifted) to raw_data
    always @(posedge clk) begin
        comp_data <= raw_data + offset[WIDTH+2:3];
    end
endmodule