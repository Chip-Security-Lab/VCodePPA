//SystemVerilog
// Top level module
module MuxLatch #(
    parameter DATA_WIDTH = 4,
    parameter SEL_WIDTH = 2
) (
    input wire clk,
    input wire [2**SEL_WIDTH-1:0][DATA_WIDTH-1:0] data_in,
    input wire [SEL_WIDTH-1:0] select,
    output wire [DATA_WIDTH-1:0] data_out
);

    wire [DATA_WIDTH-1:0] selected_data;

    // Input selection module
    MuxSelector #(
        .DATA_WIDTH(DATA_WIDTH),
        .SEL_WIDTH(SEL_WIDTH)
    ) mux_selector (
        .data_in(data_in),
        .select(select),
        .data_out(selected_data)
    );

    // Output register module
    OutputRegister #(
        .DATA_WIDTH(DATA_WIDTH)
    ) output_reg (
        .clk(clk),
        .data_in(selected_data),
        .data_out(data_out)
    );

endmodule

// Input selection module
module MuxSelector #(
    parameter DATA_WIDTH = 4,
    parameter SEL_WIDTH = 2
) (
    input wire [2**SEL_WIDTH-1:0][DATA_WIDTH-1:0] data_in,
    input wire [SEL_WIDTH-1:0] select,
    output reg [DATA_WIDTH-1:0] data_out
);

    always @(*) begin
        data_out = data_in[select];
    end

endmodule

// Output register module
module OutputRegister #(
    parameter DATA_WIDTH = 4
) (
    input wire clk,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);

    always @(posedge clk) begin
        data_out <= data_in;
    end

endmodule