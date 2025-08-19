//SystemVerilog
module width_reducer #(
    parameter IN_WIDTH = 32,
    parameter OUT_WIDTH = 8  // IN_WIDTH必须是OUT_WIDTH的整数倍
)(
    input wire clk,
    input wire reset,
    input wire in_valid,
    input wire [IN_WIDTH-1:0] data_in,
    output wire [OUT_WIDTH-1:0] data_out,
    output wire out_valid,
    output wire ready_for_input
);
    localparam RATIO = IN_WIDTH / OUT_WIDTH;
    localparam CNT_WIDTH = (RATIO > 1) ? $clog2(RATIO) : 1;

    reg [IN_WIDTH-1:0] shift_buffer_reg;
    reg [CNT_WIDTH-1:0] segment_index_reg;
    reg output_valid_reg;
    reg processing_active_reg;

    wire segment_index_last;
    wire load_new_data;

    assign segment_index_last = (segment_index_reg == (RATIO-1));
    assign load_new_data = in_valid && !processing_active_reg;

    // Shift buffer logic
    always @(posedge clk) begin
        if (reset) begin
            shift_buffer_reg <= {IN_WIDTH{1'b0}};
        end else if (load_new_data) begin
            shift_buffer_reg <= data_in;
        end else if (processing_active_reg && !segment_index_last) begin
            shift_buffer_reg <= shift_buffer_reg >> OUT_WIDTH;
        end
    end

    // Segment index logic
    always @(posedge clk) begin
        if (reset) begin
            segment_index_reg <= {CNT_WIDTH{1'b0}};
        end else if (load_new_data) begin
            segment_index_reg <= {CNT_WIDTH{1'b0}};
        end else if (processing_active_reg && !segment_index_last) begin
            segment_index_reg <= segment_index_reg + {{(CNT_WIDTH-1){1'b0}}, 1'b1};
        end
    end

    // Output valid logic
    always @(posedge clk) begin
        if (reset) begin
            output_valid_reg <= 1'b0;
        end else if (load_new_data) begin
            output_valid_reg <= 1'b1;
        end else if (processing_active_reg && segment_index_last) begin
            output_valid_reg <= 1'b0;
        end
    end

    // Processing active logic
    always @(posedge clk) begin
        if (reset) begin
            processing_active_reg <= 1'b0;
        end else if (load_new_data) begin
            processing_active_reg <= 1'b1;
        end else if (processing_active_reg && segment_index_last) begin
            processing_active_reg <= 1'b0;
        end
    end

    assign data_out = shift_buffer_reg[OUT_WIDTH-1:0];
    assign out_valid = output_valid_reg;
    assign ready_for_input = ~processing_active_reg;

endmodule