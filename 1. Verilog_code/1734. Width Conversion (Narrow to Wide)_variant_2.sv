//SystemVerilog
// Buffer control module
module buffer_ctrl #(parameter NARROW=8, WIDE=32) (
    input clk, rst_n, enable,
    input [NARROW-1:0] narrow_data,
    input narrow_valid,
    input narrow_ready,
    input buffer_full,
    output reg [WIDE-1:0] buffer,
    output reg [$clog2(WIDE/NARROW):0] count
);

    always @(posedge clk) begin
        if (!rst_n) begin
            buffer <= 0;
            count <= 0;
        end else if (enable && narrow_valid && narrow_ready) begin
            buffer <= {buffer[WIDE-NARROW-1:0], narrow_data};
            count <= count + 1;
        end
    end

endmodule

// Output control module
module output_ctrl #(parameter NARROW=8, WIDE=32) (
    input clk, rst_n, enable,
    input [WIDE-1:0] buffer,
    input [NARROW-1:0] narrow_data,
    input buffer_full,
    input wide_ready,
    output reg [WIDE-1:0] wide_data,
    output reg wide_valid,
    output reg narrow_ready
);

    always @(posedge clk) begin
        if (!rst_n) begin
            wide_valid <= 0;
            narrow_ready <= 1;
        end else if (enable) begin
            if (buffer_full) begin
                wide_data <= {narrow_data, buffer[WIDE-NARROW-1:0]};
                wide_valid <= 1;
                narrow_ready <= 0;
            end else if (wide_valid && wide_ready) begin
                wide_valid <= 0;
                narrow_ready <= 1;
            end
        end
    end

endmodule

// Top level module
module n2w_bridge #(parameter NARROW=8, WIDE=32) (
    input clk, rst_n, enable,
    input [NARROW-1:0] narrow_data,
    input narrow_valid,
    output reg narrow_ready,
    output reg [WIDE-1:0] wide_data,
    output reg wide_valid,
    input wide_ready
);

    localparam RATIO = WIDE/NARROW;
    wire [WIDE-1:0] buffer;
    wire [$clog2(RATIO):0] count;
    wire buffer_full = (count == RATIO-1);

    buffer_ctrl #(.NARROW(NARROW), .WIDE(WIDE)) buffer_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .narrow_data(narrow_data),
        .narrow_valid(narrow_valid),
        .narrow_ready(narrow_ready),
        .buffer_full(buffer_full),
        .buffer(buffer),
        .count(count)
    );

    output_ctrl #(.NARROW(NARROW), .WIDE(WIDE)) output_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .buffer(buffer),
        .narrow_data(narrow_data),
        .buffer_full(buffer_full),
        .wide_ready(wide_ready),
        .wide_data(wide_data),
        .wide_valid(wide_valid),
        .narrow_ready(narrow_ready)
    );

endmodule