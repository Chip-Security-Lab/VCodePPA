//SystemVerilog

module serial_to_parallel #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire serial_in,
    output wire [WIDTH-1:0] parallel_out,
    output wire done
);

    wire [$clog2(WIDTH):0] bit_count;
    wire load_shift;
    wire count_reset;
    wire done_set;

    // Control logic module instance
    serial_to_parallel_ctrl #(
        .WIDTH(WIDTH)
    ) ctrl_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (en),
        .bit_count  (bit_count),
        .load_shift (load_shift),
        .count_reset(count_reset),
        .done_set   (done_set)
    );

    // Bit counter module instance
    bit_counter #(
        .WIDTH(WIDTH)
    ) bit_counter_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .count_reset(count_reset),
        .load_shift (load_shift),
        .bit_count  (bit_count)
    );

    // Shift register module instance
    shift_register #(
        .WIDTH(WIDTH)
    ) shift_reg_inst (
        .clk         (clk),
        .rst_n       (rst_n),
        .load_shift  (load_shift),
        .serial_in   (serial_in),
        .parallel_out(parallel_out)
    );

    // Done signal module instance
    done_register done_reg_inst (
        .clk      (clk),
        .rst_n    (rst_n),
        .done_set (done_set),
        .load_shift(load_shift),
        .done     (done)
    );

endmodule

//--------------------- Control Logic Module ---------------------
module serial_to_parallel_ctrl #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire [$clog2(WIDTH):0] bit_count,
    output reg  load_shift,
    output reg  count_reset,
    output reg  done_set
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_shift  <= 1'b0;
            count_reset <= 1'b0;
            done_set    <= 1'b0;
        end else begin
            load_shift  <= 1'b0;
            count_reset <= 1'b0;
            done_set    <= 1'b0;
            if (en) begin
                if (bit_count == WIDTH) begin
                    count_reset <= 1'b1;
                    done_set    <= 1'b1;
                end else begin
                    load_shift  <= 1'b1;
                end
            end
        end
    end
endmodule

//--------------------- Bit Counter Module ---------------------
module bit_counter #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire count_reset,
    input wire load_shift,
    output reg [$clog2(WIDTH):0] bit_count
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count <= 0;
        end else if (count_reset) begin
            bit_count <= 0;
        end else if (load_shift) begin
            bit_count <= bit_count + 1'b1;
        end
    end
endmodule

//--------------------- Shift Register Module ---------------------
module shift_register #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire load_shift,
    input  wire serial_in,
    output reg  [WIDTH-1:0] parallel_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_out <= {WIDTH{1'b0}};
        end else if (load_shift) begin
            parallel_out <= {parallel_out[WIDTH-2:0], serial_in};
        end
    end
endmodule

//--------------------- Done Register Module ---------------------
module done_register (
    input  wire clk,
    input  wire rst_n,
    input  wire done_set,
    input  wire load_shift,
    output reg  done
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 1'b0;
        end else if (done_set) begin
            done <= 1'b1;
        end else if (load_shift) begin
            done <= 1'b0;
        end
    end
endmodule