//SystemVerilog
module MuxBusHold #(parameter W=4) (
    input [3:0][W-1:0] bus_in,
    input [1:0] sel,
    input hold,
    output reg [W-1:0] bus_out
);

    // Conditional Inversion Subtractor implementation
    wire [W-1:0] selected_bus;
    wire [W-1:0] inverted_bus;

    // Select the appropriate input from bus_in based on sel
    assign selected_bus = bus_in[sel];

    // Invert the selected input for subtraction
    assign inverted_bus = ~selected_bus + 1'b1; // Two's complement for subtraction

    // Optimized implementation using conditional logic
    always @(*) begin
        bus_out = hold ? bus_out : (selected_bus + inverted_bus);
    end

endmodule