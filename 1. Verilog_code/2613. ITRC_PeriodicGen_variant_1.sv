//SystemVerilog
// Counter submodule
module ITRC_Counter #(
    parameter PERIOD = 100
)(
    input clk,
    input rst_n,
    input en,
    output reg [$clog2(PERIOD):0] count,
    output reg period_reached
);

    always @(posedge clk) begin
        if (!rst_n) begin
            count <= 0;
            period_reached <= 0;
        end else if (en) begin
            if (count == PERIOD-1) begin
                count <= 0;
                period_reached <= 1;
            end else begin
                count <= count + 1;
                period_reached <= 0;
            end
        end
    end

endmodule

// Output control submodule
module ITRC_OutputCtrl (
    input clk,
    input rst_n,
    input en,
    input period_reached,
    output reg int_out
);

    always @(posedge clk) begin
        if (!rst_n) begin
            int_out <= 0;
        end else if (en) begin
            int_out <= period_reached;
        end
    end

endmodule

// Top level module
module ITRC_PeriodicGen #(
    parameter PERIOD = 100
)(
    input clk,
    input rst_n,
    input en,
    output int_out
);

    wire period_reached;

    ITRC_Counter #(
        .PERIOD(PERIOD)
    ) counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .count(),
        .period_reached(period_reached)
    );

    ITRC_OutputCtrl output_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .period_reached(period_reached),
        .int_out(int_out)
    );

endmodule