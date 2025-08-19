//SystemVerilog
module pipo_reg #(parameter DATA_WIDTH = 8) (
    input wire clock, reset, enable,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    // Pipeline stage registers
    reg [DATA_WIDTH-1:0] stage1_data;
    reg [DATA_WIDTH-1:0] stage2_data;
    
    // Pipeline valid signals
    reg stage1_valid;
    reg stage2_valid;
    
    // Stage 1: Input capture
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            stage1_data <= {DATA_WIDTH{1'b0}};
            stage1_valid <= 1'b0;
        end
        else if (enable) begin
            stage1_data <= data_in;
            stage1_valid <= 1'b1;
        end
        else begin
            stage1_valid <= 1'b0;
        end
    end
    
    // Stage 2: Intermediate processing
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            stage2_data <= {DATA_WIDTH{1'b0}};
            stage2_valid <= 1'b0;
        end
        else if (stage1_valid) begin
            stage2_data <= stage1_data;
            stage2_valid <= stage1_valid;
        end
        else begin
            stage2_valid <= 1'b0;
        end
    end
    
    // Final output stage
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end
        else if (stage2_valid) begin
            data_out <= stage2_data;
        end
    end
endmodule