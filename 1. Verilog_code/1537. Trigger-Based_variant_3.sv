//SystemVerilog
// IEEE 1364-2005 Verilog Standard
// Top-level module with optimized pipeline structure

module trigger_shadow_reg #(
    parameter WIDTH = 16
)(
    input  wire             clock,
    input  wire             nreset,
    input  wire [WIDTH-1:0] data_in,
    input  wire [WIDTH-1:0] trigger_value,
    output wire [WIDTH-1:0] shadow_data
);
    // Pipeline stage registers
    reg  [WIDTH-1:0] data_capture_reg;
    reg  [WIDTH-1:0] data_pipeline_reg;
    wire [WIDTH-1:0] data_to_shadow;
    
    // Trigger detection signals
    reg              trigger_matched_stage1;
    wire             trigger_detected;
    reg              trigger_valid_reg;
    
    // Stage 1: Data Capture Pipeline
    always @(posedge clock or negedge nreset) begin
        if (~nreset) begin
            data_capture_reg <= {WIDTH{1'b0}};
        end else begin
            data_capture_reg <= data_in;
        end
    end
    
    // Stage 2: Data Pipeline and Trigger Detection
    always @(posedge clock or negedge nreset) begin
        if (~nreset) begin
            data_pipeline_reg    <= {WIDTH{1'b0}};
            trigger_matched_stage1 <= 1'b0;
        end else begin
            data_pipeline_reg    <= data_capture_reg;
            trigger_matched_stage1 <= (data_capture_reg == trigger_value);
        end
    end
    
    // Combinational comparison for final stage
    assign trigger_detected = trigger_matched_stage1;
    assign data_to_shadow = data_pipeline_reg;
    
    // Stage 3: Shadow Register Control
    always @(posedge clock or negedge nreset) begin
        if (~nreset) begin
            trigger_valid_reg <= 1'b0;
        end else begin
            trigger_valid_reg <= trigger_detected;
        end
    end
    
    // Shadow Register Module
    shadow_register #(
        .WIDTH(WIDTH)
    ) shadow_reg_inst (
        .clock          (clock),
        .nreset         (nreset),
        .data_in        (data_to_shadow),
        .trigger_valid  (trigger_valid_reg),
        .shadow_data_out(shadow_data)
    );
    
endmodule

// Optimized Shadow Register module
module shadow_register #(
    parameter WIDTH = 16
)(
    input  wire             clock,
    input  wire             nreset,
    input  wire [WIDTH-1:0] data_in,
    input  wire             trigger_valid,
    output reg  [WIDTH-1:0] shadow_data_out
);
    // Shadow register update logic
    always @(posedge clock or negedge nreset) begin
        if (~nreset) begin
            shadow_data_out <= {WIDTH{1'b0}};
        end else if (trigger_valid) begin
            shadow_data_out <= data_in;
        end
    end
endmodule