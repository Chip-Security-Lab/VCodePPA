//SystemVerilog
// Top-level module
module int_ctrl_threshold #(
    parameter WIDTH = 6,
    parameter THRESHOLD = 3
)(
    input clk, rst,
    input [WIDTH-1:0] req,
    output valid,
    output [2:0] code
);
    // Internal signals
    wire [WIDTH-1:0] masked_req;
    wire threshold_detector_valid;
    wire [2:0] priority_encoder_code;
    
    // Threshold detector module instance
    req_threshold_detector #(
        .WIDTH(WIDTH),
        .THRESHOLD(THRESHOLD)
    ) threshold_det_inst (
        .req(req),
        .masked_req(masked_req),
        .valid(threshold_detector_valid)
    );
    
    // Priority encoder module instance
    priority_encoder #(
        .WIDTH(WIDTH)
    ) pri_enc_inst (
        .clk(clk),
        .rst(rst),
        .masked_req(masked_req),
        .valid(threshold_detector_valid),
        .code(priority_encoder_code)
    );
    
    // Output register module instance
    output_register out_reg_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(threshold_detector_valid),
        .code_in(priority_encoder_code),
        .valid_out(valid),
        .code_out(code)
    );
    
endmodule

// Module for threshold detection functionality
module req_threshold_detector #(
    parameter WIDTH = 6,
    parameter THRESHOLD = 3
)(
    input [WIDTH-1:0] req,
    output [WIDTH-1:0] masked_req,
    output valid
);
    // Optimized threshold detection logic
    wire [WIDTH-1:0] threshold_mask = {WIDTH{1'b1}} << THRESHOLD;
    assign masked_req = req & threshold_mask;
    assign valid = |masked_req;
    
endmodule

// Module for priority encoding
module priority_encoder #(
    parameter WIDTH = 6
)(
    input clk,
    input rst,
    input [WIDTH-1:0] masked_req,
    input valid,
    output reg [2:0] code
);
    // Optimized priority encoder with one-hot detection
    reg [2:0] next_code;
    
    always @(*) begin
        next_code = 3'b0;
        casez (masked_req)
            // From highest to lowest priority (MSB to LSB)
            {1'b1, {(WIDTH-1){1'b?}}}: next_code = WIDTH - 1;
            {{1'b0, 1'b1, {(WIDTH-2){1'b?}}}}: next_code = WIDTH - 2;
            {{2'b00, 1'b1, {(WIDTH-3){1'b?}}}}: next_code = WIDTH - 3;
            {{3'b000, 1'b1, {(WIDTH-4){1'b?}}}}: next_code = WIDTH - 4;
            {{4'b0000, 1'b1, {(WIDTH-5){1'b?}}}}: next_code = WIDTH - 5;
            {{5'b00000, 1'b1}}: next_code = WIDTH - 6;
            default: next_code = 3'b0;
        endcase
    end
    
    always @(posedge clk) begin
        if (rst) begin
            code <= 3'b0;
        end else if (valid) begin
            code <= next_code;
        end
    end
    
endmodule

// Module for output register stage
module output_register (
    input clk,
    input rst,
    input valid_in,
    input [2:0] code_in,
    output reg valid_out,
    output reg [2:0] code_out
);
    // Optimized output register with enable logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_out <= 1'b0;
            code_out <= 3'b0;
        end else begin
            valid_out <= valid_in;
            code_out <= code_in;
        end
    end
    
endmodule