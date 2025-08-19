//SystemVerilog
// Pipelined counter submodule
module counter #(
    parameter COUNTER_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [COUNTER_WIDTH-1:0] period,
    output reg [COUNTER_WIDTH-1:0] count,
    output reg period_reached
);
    // Stage 1: Comparison logic
    reg [COUNTER_WIDTH-1:0] count_stage1;
    reg comparison_result_stage1;
    
    // Stage 2: Update logic
    reg [COUNTER_WIDTH-1:0] count_stage2;
    reg period_reached_stage2;
    
    // Pipeline stage 1: Compare current count with period
    always @(posedge clk) begin
        if (!rst_n) begin
            count_stage1 <= 0;
            comparison_result_stage1 <= 0;
        end else begin
            count_stage1 <= count;
            comparison_result_stage1 <= (count >= period - 1);
        end
    end
    
    // Pipeline stage 2: Update count and generate period_reached
    always @(posedge clk) begin
        if (!rst_n) begin
            count_stage2 <= 0;
            period_reached_stage2 <= 0;
        end else begin
            if (comparison_result_stage1) begin
                count_stage2 <= 0;
                period_reached_stage2 <= 1;
            end else begin
                count_stage2 <= count_stage1 + 1;
                period_reached_stage2 <= 0;
            end
        end
    end
    
    // Output registers
    always @(posedge clk) begin
        if (!rst_n) begin
            count <= 0;
            period_reached <= 0;
        end else begin
            count <= count_stage2;
            period_reached <= period_reached_stage2;
        end
    end

endmodule

// Pipelined output control submodule
module output_control (
    input wire clk,
    input wire rst_n,
    input wire period_reached,
    output reg out
);
    // Pipeline stage 1: Capture period reached signal
    reg period_reached_stage1;
    
    // Pipeline stage 2: Compute next output value
    reg next_out_stage2;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            period_reached_stage1 <= 0;
        end else begin
            period_reached_stage1 <= period_reached;
        end
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            next_out_stage2 <= 0;
        end else if (period_reached_stage1) begin
            next_out_stage2 <= ~out;
        end else begin
            next_out_stage2 <= out;
        end
    end
    
    // Output register
    always @(posedge clk) begin
        if (!rst_n) begin
            out <= 0;
        end else begin
            out <= next_out_stage2;
        end
    end

endmodule

// Top level pipelined module
module square_wave_gen #(
    parameter COUNTER_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [COUNTER_WIDTH-1:0] period,
    output wire out
);
    // Pipeline control signals
    wire period_reached;
    reg [COUNTER_WIDTH-1:0] period_stage1, period_stage2;
    
    // Pipeline the period input
    always @(posedge clk) begin
        if (!rst_n) begin
            period_stage1 <= 0;
            period_stage2 <= 0;
        end else begin
            period_stage1 <= period;
            period_stage2 <= period_stage1;
        end
    end

    counter #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .period(period_stage2),
        .count(),
        .period_reached(period_reached)
    );

    output_control output_control_inst (
        .clk(clk),
        .rst_n(rst_n),
        .period_reached(period_reached),
        .out(out)
    );

endmodule