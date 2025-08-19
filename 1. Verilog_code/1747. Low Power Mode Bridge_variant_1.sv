//SystemVerilog
module pipeline_stage #(
    parameter DWIDTH = 32
) (
    input clk,
    input rst_n,
    input clk_en,
    input [DWIDTH-1:0] in_data,
    input in_valid,
    input power_save,
    input next_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    output reg out_ready,
    output reg active
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active <= 1;
            out_valid <= 0;
            out_ready <= 1;
            out_data <= 0;
        end else if (clk_en) begin
            if (power_save && out_valid && next_ready) begin
                active <= 0;
            end else if (!power_save) begin
                active <= 1;
            end
            
            if (active) begin
                if (in_valid && out_ready) begin
                    out_data <= in_data;
                    out_valid <= 1;
                    out_ready <= 0;
                end else if (out_valid && next_ready) begin
                    out_valid <= 0;
                    out_ready <= 1;
                end
            end
        end
    end

endmodule

module low_power_bridge #(
    parameter DWIDTH = 32
) (
    input clk,
    input rst_n,
    input clk_en,
    input [DWIDTH-1:0] in_data,
    input in_valid,
    input power_save,
    output reg in_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    input out_ready
);

    wire [DWIDTH-1:0] stage1_data;
    wire stage1_valid;
    wire stage1_ready;
    wire stage1_active;

    wire [DWIDTH-1:0] stage2_data;
    wire stage2_valid;
    wire stage2_ready;
    wire stage2_active;

    pipeline_stage #(.DWIDTH(DWIDTH)) stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .clk_en(clk_en),
        .in_data(in_data),
        .in_valid(in_valid),
        .power_save(power_save),
        .next_ready(stage2_ready),
        .out_data(stage1_data),
        .out_valid(stage1_valid),
        .out_ready(stage1_ready),
        .active(stage1_active)
    );

    pipeline_stage #(.DWIDTH(DWIDTH)) stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .clk_en(clk_en),
        .in_data(stage1_data),
        .in_valid(stage1_valid),
        .power_save(power_save),
        .next_ready(out_ready),
        .out_data(stage2_data),
        .out_valid(stage2_valid),
        .out_ready(stage2_ready),
        .active(stage2_active)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 0;
            out_valid <= 0;
            in_ready <= 1;
        end else if (clk_en) begin
            if (stage2_active) begin
                out_data <= stage2_data;
                out_valid <= stage2_valid;
                in_ready <= stage1_ready;
            end
        end
    end

endmodule