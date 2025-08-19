//SystemVerilog
// Top level module
module sync_low_pass_filter #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n, 
    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out
);

    // Internal signals
    wire [DATA_WIDTH-1:0] filtered_data;
    wire [DATA_WIDTH-1:0] prev_sample;

    // Filter calculation module
    filter_calc #(
        .DATA_WIDTH(DATA_WIDTH)
    ) filter_calc_inst (
        .data_in(data_in),
        .prev_sample(prev_sample),
        .filtered_data(filtered_data)
    );

    // Register module
    filter_reg #(
        .DATA_WIDTH(DATA_WIDTH)
    ) filter_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .filtered_data(filtered_data),
        .data_out(data_out),
        .prev_sample(prev_sample)
    );

endmodule

// Filter calculation module
module filter_calc #(
    parameter DATA_WIDTH = 8
)(
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [DATA_WIDTH-1:0] prev_sample,
    output wire [DATA_WIDTH-1:0] filtered_data
);

    // Internal signals for intermediate calculations
    wire [DATA_WIDTH-1:0] data_in_quarter;
    wire [DATA_WIDTH-1:0] data_in_half;
    wire [DATA_WIDTH-1:0] prev_sample_quarter;

    // Calculate intermediate values
    assign data_in_quarter = data_in >> 2;
    assign data_in_half = data_in >> 1;
    assign prev_sample_quarter = prev_sample >> 2;

    // Final filtered output calculation
    assign filtered_data = data_in_quarter + data_in_half + prev_sample_quarter;

endmodule

// Register module
module filter_reg #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] filtered_data,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg [DATA_WIDTH-1:0] prev_sample
);

    // Reset logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end
    end

    // Data output register
    always @(posedge clk) begin
        if (rst_n) begin
            data_out <= filtered_data;
        end
    end

    // Previous sample register
    always @(posedge clk) begin
        if (rst_n) begin
            prev_sample <= data_out;
        end
    end

endmodule