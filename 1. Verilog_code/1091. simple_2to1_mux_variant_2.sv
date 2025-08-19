//SystemVerilog
// Top-level 2-to-1 multiplexer module with pipelined and structured data path
module simple_2to1_mux (
    input  wire data0,     // Data input 0
    input  wire data1,     // Data input 1
    input  wire sel,       // Selection signal
    input  wire clk,       // System clock for pipelining
    input  wire rst_n,     // Active-low synchronous reset
    output wire mux_out    // Output data
);

    // Stage 1: Latch inputs and selection signal
    wire        data0_stage1;
    wire        data1_stage1;
    wire        sel_stage1;

    pipeline_reg #(.WIDTH(1)) u_data0_stage1 (
        .clk   (clk),
        .rst_n (rst_n),
        .d_in  (data0),
        .d_out (data0_stage1)
    );
    pipeline_reg #(.WIDTH(1)) u_data1_stage1 (
        .clk   (clk),
        .rst_n (rst_n),
        .d_in  (data1),
        .d_out (data1_stage1)
    );
    pipeline_reg #(.WIDTH(1)) u_sel_stage1 (
        .clk   (clk),
        .rst_n (rst_n),
        .d_in  (sel),
        .d_out (sel_stage1)
    );

    // Stage 2: Selection logic (combinational)
    wire selected_data_stage2;
    mux_selector u_mux_selector (
        .in0 (data0_stage1),
        .in1 (data1_stage1),
        .sel (sel_stage1),
        .out (selected_data_stage2)
    );

    // Stage 3: Pipeline register after selection
    wire selected_data_stage3;
    pipeline_reg #(.WIDTH(1)) u_selected_data_stage3 (
        .clk   (clk),
        .rst_n (rst_n),
        .d_in  (selected_data_stage2),
        .d_out (selected_data_stage3)
    );

    // Stage 4: Output driver
    mux_output_driver u_mux_output_driver (
        .data_in  (selected_data_stage3),
        .data_out (mux_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Pipeline Register Module
// Parameterized width, positive-edge clocked, synchronous active-low reset
// -----------------------------------------------------------------------------
module pipeline_reg #(
    parameter WIDTH = 1
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] d_in,
    output reg  [WIDTH-1:0] d_out
);
    always @(posedge clk) begin
        if (!rst_n)
            d_out <= {WIDTH{1'b0}};
        else
            d_out <= d_in;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: mux_selector
// Function: Selects one of the two input data signals based on the selection signal
// -----------------------------------------------------------------------------
module mux_selector (
    input  wire in0,     // Data input 0
    input  wire in1,     // Data input 1
    input  wire sel,     // Selection signal
    output wire out      // Selected data output
);
    assign out = sel ? in1 : in0;
endmodule

// -----------------------------------------------------------------------------
// Submodule: mux_output_driver
// Function: Drives the selected data to the output, allows for future output logic expansion
// -----------------------------------------------------------------------------
module mux_output_driver (
    input  wire data_in,   // Selected data input
    output wire data_out   // Output data
);
    assign data_out = data_in;
endmodule