//SystemVerilog
//IEEE 1364-2005 Verilog
module serial_to_parallel #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire serial_in,
    output reg [WIDTH-1:0] parallel_out,
    output reg done
);

    reg [$clog2(WIDTH):0] bit_count;
    reg serial_in_reg;
    wire [WIDTH-1:0] next_parallel_out;
    wire [$clog2(WIDTH):0] next_bit_count;
    wire next_done;

    // 前向寄存器重定时：将serial_in采样寄存器移动到组合逻辑后面
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_in_reg <= 1'b0;
        end else if (en) begin
            serial_in_reg <= serial_in;
        end
    end

    assign next_parallel_out = (bit_count == WIDTH) ? {WIDTH{1'b0}} : {parallel_out[WIDTH-2:0], serial_in_reg};
    assign next_bit_count = (bit_count == WIDTH) ? 0 : bit_count + 1;
    assign next_done = (bit_count == WIDTH) ? 1'b1 : 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count <= 0;
            parallel_out <= {WIDTH{1'b0}};
            done <= 1'b0;
        end else if (en) begin
            bit_count <= next_bit_count;
            parallel_out <= next_parallel_out;
            done <= next_done;
        end
    end

endmodule