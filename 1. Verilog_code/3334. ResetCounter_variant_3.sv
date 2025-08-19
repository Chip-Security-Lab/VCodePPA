//SystemVerilog
module ResetCounter #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    output reg [WIDTH-1:0] reset_count
);

    // Pipeline stage registers
    reg rst_n_stage1;
    reg rst_n_stage2;
    reg valid_stage1;
    reg valid_stage2;
    reg [WIDTH-1:0] reset_count_stage1;
    reg [WIDTH-1:0] reset_count_stage2;

    // Pipeline flush logic
    wire flush;
    assign flush = 1'b0; // No explicit flush in simple counter, can be extended

    // Stage 1: Capture rst_n and reset_count
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_stage1 <= 1'b0;
            reset_count_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (flush) begin
            rst_n_stage1 <= 1'b0;
            reset_count_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            rst_n_stage1 <= rst_n;
            reset_count_stage1 <= reset_count;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Compute reset_count increment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_stage2 <= 1'b0;
            reset_count_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (flush) begin
            rst_n_stage2 <= 1'b0;
            reset_count_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            rst_n_stage2 <= rst_n_stage1;
            if (!rst_n_stage1 && valid_stage1)
                reset_count_stage2 <= reset_count_stage1 + 1'b1;
            else
                reset_count_stage2 <= reset_count_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_count <= {WIDTH{1'b0}};
        end else if (flush) begin
            reset_count <= {WIDTH{1'b0}};
        end else if (valid_stage2) begin
            reset_count <= reset_count_stage2;
        end
    end

endmodule