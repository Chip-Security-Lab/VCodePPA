//SystemVerilog
module param_mux_array #(
    parameter CHANNELS = 4,
    parameter WIDTH = 8,
    parameter SEL_BITS = $clog2(CHANNELS)
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in [0:CHANNELS-1],
    input [SEL_BITS-1:0] channel_sel,
    output reg [WIDTH-1:0] data_out
);

    // Pipeline stage 1 registers
    reg [SEL_BITS-1:0] channel_sel_stage1;
    reg [WIDTH-1:0] selected_data_stage1;
    reg valid_stage1;

    // Pipeline stage 2 registers
    reg [WIDTH-1:0] selected_data_stage2;
    reg valid_stage2;

    // Pipeline stage 1: Channel selection and validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            channel_sel_stage1 <= {SEL_BITS{1'b0}};
            selected_data_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            channel_sel_stage1 <= channel_sel;
            selected_data_stage1 <= data_in[channel_sel];
            valid_stage1 <= 1'b1;
        end
    end

    // Pipeline stage 2: Data processing and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_data_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            data_out <= {WIDTH{1'b0}};
        end else begin
            selected_data_stage2 <= selected_data_stage1;
            valid_stage2 <= valid_stage1;
            if (valid_stage2) begin
                data_out <= selected_data_stage2;
            end
        end
    end

endmodule