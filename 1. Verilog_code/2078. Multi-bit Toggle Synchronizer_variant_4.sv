//SystemVerilog
module multibit_toggle_sync #(parameter WIDTH = 4) (
    input wire src_clk,
    input wire dst_clk,
    input wire reset,
    input wire [WIDTH-1:0] data_src,
    input wire update,
    output reg [WIDTH-1:0] data_dst
);
    reg toggle_src;
    reg [WIDTH-1:0] data_captured;
    reg [2:0] sync_toggle_dst_pipeline;
    reg [2:0] sync_toggle_dst;
    reg [WIDTH-1:0] data_captured_pipeline;
    reg pipeline_toggle_detected;
    reg pipeline_toggle_detected_d;
    reg [WIDTH-1:0] pipeline_data_to_dst;

    // Source domain logic
    always @(posedge src_clk) begin
        if (reset) begin
            toggle_src <= 1'b0;
            data_captured <= {WIDTH{1'b0}};
        end else if (update) begin
            toggle_src <= ~toggle_src;
            data_captured <= data_src;
        end
    end

    // Pipeline stage 1: Synchronize toggle_src into dst_clk domain (3-stage shift reg)
    always @(posedge dst_clk) begin
        if (reset) begin
            sync_toggle_dst_pipeline <= 3'b0;
        end else begin
            sync_toggle_dst_pipeline <= {sync_toggle_dst_pipeline[1:0], toggle_src};
        end
    end

    // Pipeline stage 2: Register sync_toggle_dst and data_captured
    always @(posedge dst_clk) begin
        if (reset) begin
            sync_toggle_dst <= 3'b0;
            data_captured_pipeline <= {WIDTH{1'b0}};
        end else begin
            sync_toggle_dst <= sync_toggle_dst_pipeline;
            data_captured_pipeline <= data_captured;
        end
    end

    // Pipeline stage 3: Toggle detection and register data for output
    always @(posedge dst_clk) begin
        if (reset) begin
            pipeline_toggle_detected <= 1'b0;
            pipeline_data_to_dst <= {WIDTH{1'b0}};
        end else begin
            pipeline_toggle_detected <= ^sync_toggle_dst[2:1];
            pipeline_data_to_dst <= data_captured_pipeline;
        end
    end

    // Pipeline stage 4: Output register for data_dst
    always @(posedge dst_clk) begin
        if (reset) begin
            data_dst <= {WIDTH{1'b0}};
            pipeline_toggle_detected_d <= 1'b0;
        end else begin
            pipeline_toggle_detected_d <= pipeline_toggle_detected;
            if (pipeline_toggle_detected_d)
                data_dst <= pipeline_data_to_dst;
        end
    end
endmodule