//SystemVerilog
module ResetCounter #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    output reg [WIDTH-1:0] reset_count
);

    reg rst_n_stage1;
    reg rst_n_stage2;
    reg reset_event_stage1;
    reg reset_event_stage2;
    reg [WIDTH-1:0] count_stage1;
    reg [WIDTH-1:0] count_stage2;

    // Pipeline stage 1: synchronize and detect reset event
    always @(posedge clk) begin
        rst_n_stage1 <= rst_n;
        reset_event_stage1 <= (~rst_n) & rst_n_stage1; // detect falling edge of rst_n
        count_stage1 <= reset_count;
    end

    // Pipeline stage 2: prepare next count value
    always @(posedge clk) begin
        rst_n_stage2 <= rst_n_stage1;
        reset_event_stage2 <= reset_event_stage1;
        if (reset_event_stage1) begin
            count_stage2 <= count_stage1 + 1'b1;
        end else begin
            count_stage2 <= count_stage1;
        end
    end

    // Pipeline stage 3: update output register
    always @(posedge clk) begin
        if (reset_event_stage2) begin
            reset_count <= count_stage2;
        end
    end

endmodule