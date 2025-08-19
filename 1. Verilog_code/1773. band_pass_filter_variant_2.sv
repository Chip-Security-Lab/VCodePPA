//SystemVerilog
module band_pass_filter #(
    parameter WIDTH = 12
)(
    input clk, arst,
    input [WIDTH-1:0] x_in,
    input valid_in,
    output reg [WIDTH-1:0] y_out,
    output reg valid_out
);
    // Stage 1 registers
    reg [WIDTH-1:0] x_in_stage1;
    reg [WIDTH-1:0] lp_out;
    reg [WIDTH-1:0] hp_temp_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [WIDTH-1:0] hp_out_stage2;
    reg valid_stage2;
    
    // Stage 1: Input capture and low-pass filter computation
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            x_in_stage1 <= {WIDTH{1'b0}};
            lp_out <= {WIDTH{1'b0}};
            hp_temp_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            // Capture input data
            x_in_stage1 <= x_in;
            // Low-pass filter computation
            lp_out <= lp_out + ((x_in - lp_out) >>> 3);
            // High-pass filter first stage
            hp_temp_stage1 <= x_in - lp_out;
            // Propagate valid signal
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: High-pass filter operation
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            hp_out_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            hp_out_stage2 <= hp_temp_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output stage
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            y_out <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            y_out <= hp_out_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule