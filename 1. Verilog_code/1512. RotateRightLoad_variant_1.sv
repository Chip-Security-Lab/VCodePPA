//SystemVerilog
module RotateRightLoad #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  load_en,
    input  wire [DATA_WIDTH-1:0] parallel_in,
    output reg  [DATA_WIDTH-1:0] data,
    output reg                   valid_out
);

    // Pipeline stage 1 - Input register
    reg [DATA_WIDTH-1:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 - Rotation logic
    reg [DATA_WIDTH-1:0] data_stage2;
    reg valid_stage2;

    // Stage 1: Input register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {DATA_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            if (load_en) begin
                data_stage1 <= parallel_in;
                valid_stage1 <= 1'b1;
            end else begin
                data_stage1 <= data;
                valid_stage1 <= 1'b1;
            end
        end
    end

    // Stage 2: Rotation logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= {data_stage1[0], data_stage1[DATA_WIDTH-1:1]};
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            data <= data_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule