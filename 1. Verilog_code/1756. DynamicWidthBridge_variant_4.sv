//SystemVerilog

// Submodule to handle count and valid signal computation
module CountValidLogic #(
    parameter RATIO = 2
)(
    input in_valid,
    input [3:0] count,
    output reg [3:0] next_count,
    output reg next_valid
);
    always @(*) begin
        if (in_valid) begin
            next_count = (count == RATIO-1) ? 4'd0 : count + 4'd1;
            next_valid = (count == RATIO-1);
        end else begin
            next_count = count;
            next_valid = 1'b0;
        end
    end
endmodule

// Submodule for output register management
module OutputRegister #(
    parameter OUT_W = 64
)(
    input clk,
    input rst_n,
    input in_valid,
    input [OUT_W-1:0] shift_reg,
    input next_valid,
    output reg [OUT_W-1:0] data_out_reg,
    output reg out_valid_reg
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg <= {OUT_W{1'b0}};
            out_valid_reg <= 1'b0;
        end else begin
            // Update output registers
            data_out_reg <= shift_reg;
            out_valid_reg <= next_valid & in_valid;
        end
    end
endmodule

// Pipelined submodule for count and valid signal computation
module PipelinedCountValidLogic #(
    parameter RATIO = 2
)(
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] count,
    output reg [3:0] next_count,
    output reg next_valid
);
    reg in_valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_valid_reg <= 1'b0;
        end else begin
            in_valid_reg <= in_valid;
        end
    end

    always @(*) begin
        if (in_valid_reg) begin
            next_count = (count == RATIO-1) ? 4'd0 : count + 4'd1;
            next_valid = (count == RATIO-1);
        end else begin
            next_count = count;
            next_valid = 1'b0;
        end
    end
endmodule

// Top-level module
module DynamicWidthBridge #(
    parameter IN_W = 32,
    parameter OUT_W = 64
)(
    input clk, rst_n,
    input [IN_W-1:0] data_in,
    input in_valid,
    output [OUT_W-1:0] data_out,
    output out_valid
);
    localparam RATIO = OUT_W / IN_W;
    
    // Internal signals
    reg [3:0] count_stage1, count_stage2;
    reg [3:0] next_count_stage1, next_count_stage2;
    reg next_valid_stage1, next_valid_stage2;
    reg [OUT_W-1:0] shift_reg_stage1, shift_reg_stage2;

    // Instantiate PipelinedCountValidLogic submodule
    PipelinedCountValidLogic #(.RATIO(RATIO)) count_valid_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .count(count_stage1),
        .next_count(next_count_stage1),
        .next_valid(next_valid_stage1)
    );

    // Instantiate OutputRegister submodule
    OutputRegister #(.OUT_W(OUT_W)) output_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .shift_reg(shift_reg_stage2),
        .next_valid(next_valid_stage2),
        .data_out_reg(data_out),
        .out_valid_reg(out_valid)
    );

    // Register update logic for shift register and count
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage1 <= 4'd0;
            count_stage2 <= 4'd0;
            shift_reg_stage1 <= {OUT_W{1'b0}};
            shift_reg_stage2 <= {OUT_W{1'b0}};
        end else begin
            if (in_valid) begin
                // Stage 1: Update count and shift register
                shift_reg_stage1 <= {data_in, shift_reg_stage1[OUT_W-1:IN_W]};
                count_stage1 <= next_count_stage1;

                // Stage 2: Pass through values
                shift_reg_stage2 <= shift_reg_stage1;
                count_stage2 <= count_stage1;
                next_valid_stage2 <= next_valid_stage1;
            end
        end
    end

endmodule