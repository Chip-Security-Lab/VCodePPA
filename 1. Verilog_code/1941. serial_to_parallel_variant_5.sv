//SystemVerilog
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
    wire bit_count_max;
    wire load_enable;

    assign bit_count_max = (bit_count == WIDTH);
    assign load_enable = en & ~bit_count_max;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count     <= {($clog2(WIDTH)+1){1'b0}};
            parallel_out  <= {WIDTH{1'b0}};
            done          <= 1'b0;
        end else begin
            done <= 1'b0;
            if (en) begin
                if (bit_count_max) begin
                    bit_count <= {($clog2(WIDTH)+1){1'b0}};
                    done      <= 1'b1;
                    // parallel_out unchanged
                end else begin
                    parallel_out <= {parallel_out[WIDTH-2:0], serial_in};
                    bit_count    <= bit_count + 1'b1;
                    // done already cleared
                end
            end
        end
    end

endmodule