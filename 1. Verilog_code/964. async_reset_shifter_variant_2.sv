//SystemVerilog
// Top level module
module async_reset_shifter #(parameter WIDTH = 10) (
    input wire i_clk, i_arst_n, i_en,
    input wire i_data,
    output wire o_data
);
    // Internal signals for connecting submodules
    wire [WIDTH-1:0] w_shifter_data;
    
    // Control unit instantiation
    async_shifter_control control_unit (
        .i_clk(i_clk),
        .i_arst_n(i_arst_n),
        .i_en(i_en),
        .i_data(i_data),
        .o_shifter_data(w_shifter_data)
    );
    
    // Output unit instantiation
    async_shifter_output #(.WIDTH(WIDTH)) output_unit (
        .i_shifter_data(w_shifter_data),
        .o_data(o_data)
    );
endmodule

// Control unit submodule - handles shift register logic with async reset
module async_shifter_control #(parameter WIDTH = 10) (
    input wire i_clk, i_arst_n, i_en,
    input wire i_data,
    output reg [WIDTH-1:0] o_shifter_data
);
    // Shift register with asynchronous reset
    always @(posedge i_clk or negedge i_arst_n) begin
        if (!i_arst_n) begin
            // Reset condition
            o_shifter_data <= {WIDTH{1'b0}};
        end else if (i_en) begin
            // Enabled shift operation
            o_shifter_data <= {i_data, o_shifter_data[WIDTH-1:1]};
        end
        // Else: maintain current state (implicit)
    end
endmodule

// Output unit submodule - handles data output
module async_shifter_output #(parameter WIDTH = 10) (
    input wire [WIDTH-1:0] i_shifter_data,
    output wire o_data
);
    // Extract LSB for output
    assign o_data = i_shifter_data[0];
endmodule