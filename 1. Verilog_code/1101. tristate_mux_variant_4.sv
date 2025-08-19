//SystemVerilog
module tristate_mux (
    input  wire        clk,                // Clock for pipelining
    input  wire [7:0]  source_a,           // Data source A
    input  wire [7:0]  source_b,           // Data source B
    input  wire        select,             // Selection control
    input  wire        output_enable,      // Output enable
    output wire [7:0]  data_bus            // Tristate output bus
);

    // Pipeline Stage 1: Register inputs for data path clarity
    reg [7:0] source_a_reg;
    reg [7:0] source_b_reg;
    reg       select_reg;
    reg       output_enable_reg;

    always @(posedge clk) begin
        source_a_reg      <= source_a;
        source_b_reg      <= source_b;
        select_reg        <= select;
        output_enable_reg <= output_enable;
    end

    // Pipeline Stage 2: Multiplexing stage
    reg [7:0] mux_stage_data;
    always @(posedge clk) begin
        if (select_reg) begin
            mux_stage_data <= source_b_reg;
        end else begin
            mux_stage_data <= source_a_reg;
        end
    end

    // Pipeline Stage 3: Output enable control
    reg [7:0] tristate_output_reg;
    always @(posedge clk) begin
        if (output_enable_reg) begin
            tristate_output_reg <= mux_stage_data;
        end else begin
            tristate_output_reg <= 8'bz;
        end
    end

    // Assign to output bus
    assign data_bus = tristate_output_reg;

endmodule