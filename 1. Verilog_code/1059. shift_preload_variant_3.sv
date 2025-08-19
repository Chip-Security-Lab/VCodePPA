//SystemVerilog
module shift_preload_pipeline #(parameter WIDTH=8) (
    input clk,
    input rst_n,
    input load,
    input [WIDTH-1:0] load_data,
    input valid_in,
    output reg [WIDTH-1:0] sr_out,
    output reg valid_out
);

    // Stage 1: Load decision and data latching
    reg load_stage1;
    reg [WIDTH-1:0] load_data_stage1;
    reg [WIDTH-1:0] sr_stage1;
    reg valid_stage1;

    // Stage 2: Shift or load operation
    reg [WIDTH-1:0] sr_stage2;
    reg valid_stage2;

    // Pipeline Register: Stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_stage1       <= 1'b0;
            load_data_stage1  <= {WIDTH{1'b0}};
            sr_stage1         <= {WIDTH{1'b0}};
            valid_stage1      <= 1'b0;
        end else begin
            load_stage1       <= load;
            load_data_stage1  <= load_data;
            // For first cycle, sr_stage1 is zero, then passes from stage2
            sr_stage1         <= sr_stage2;
            valid_stage1      <= valid_in;
        end
    end

    // Pipeline Register: Stage 2 and Operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sr_stage2    <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            if (load_stage1 && valid_stage1) begin
                sr_stage2 <= load_data_stage1;
            end else if (valid_stage1) begin
                sr_stage2 <= {sr_stage1[WIDTH-2:0], 1'b0};
            end
            valid_stage2 <= valid_stage1;
        end
    end

    // Output register (optional, can be used for timing closure)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sr_out    <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            sr_out    <= sr_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule