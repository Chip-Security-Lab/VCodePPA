//SystemVerilog
module sync_low_pass_filter #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire data_valid_in,
    input wire [DATA_WIDTH-1:0] data_in,
    output wire data_valid_out,
    output wire [DATA_WIDTH-1:0] data_out
);
    // Control signals for pipeline stages
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg valid_out_reg;
    
    // Data path registers
    reg [DATA_WIDTH-1:0] data_stage1;
    reg [DATA_WIDTH-1:0] data_stage2;
    reg [DATA_WIDTH-1:0] prev_sample_stage2;
    reg [DATA_WIDTH-1:0] data_shifted1_stage3;
    reg [DATA_WIDTH-1:0] prev_sample_stage3;
    reg [DATA_WIDTH-1:0] data_shifted2_stage4;
    reg [DATA_WIDTH-1:0] prev_shifted_stage4;
    reg [DATA_WIDTH-1:0] data_out_reg;
    reg [DATA_WIDTH-1:0] prev_sample_reg;
    
    // Combinational calculation signals
    reg [DATA_WIDTH-1:0] shifted1_next;
    reg [DATA_WIDTH-1:0] shifted2_next;
    reg [DATA_WIDTH-1:0] prev_shifted_next;
    reg [DATA_WIDTH-1:0] filter_result;
    
    // Assignments for output ports
    assign data_out = data_out_reg;
    assign data_valid_out = valid_out_reg;
    
    // Pipeline Stage 1: Register inputs
    always @(posedge clk) begin
        if (!rst_n) begin
            data_stage1 <= {DATA_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            valid_stage1 <= data_valid_in;
        end
    end
    
    // Pipeline Stage 2: Register previous sample
    always @(posedge clk) begin
        if (!rst_n) begin
            data_stage2 <= {DATA_WIDTH{1'b0}};
            prev_sample_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            prev_sample_stage2 <= prev_sample_reg;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Calculate shifted values (combinational)
    always @(*) begin
        shifted1_next = data_stage2 >> 1;
        shifted2_next = data_stage2 >> 2;
        prev_shifted_next = prev_sample_stage2 >> 2;
    end
    
    // Pipeline Stage 3: Register shift operations
    always @(posedge clk) begin
        if (!rst_n) begin
            data_shifted1_stage3 <= {DATA_WIDTH{1'b0}};
            data_shifted2_stage4 <= {DATA_WIDTH{1'b0}};
            prev_shifted_stage4 <= {DATA_WIDTH{1'b0}};
            prev_sample_stage3 <= {DATA_WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            data_shifted1_stage3 <= shifted1_next;
            data_shifted2_stage4 <= shifted2_next;
            prev_shifted_stage4 <= prev_shifted_next;
            prev_sample_stage3 <= prev_sample_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Calculate filter result (combinational)
    always @(*) begin
        filter_result = data_shifted1_stage3 + data_shifted2_stage4 + prev_shifted_stage4;
    end
    
    // Final stage: Register output
    always @(posedge clk) begin
        if (!rst_n) begin
            data_out_reg <= {DATA_WIDTH{1'b0}};
            prev_sample_reg <= {DATA_WIDTH{1'b0}};
            valid_out_reg <= 1'b0;
        end else begin
            data_out_reg <= filter_result;
            prev_sample_reg <= data_out_reg;
            valid_out_reg <= valid_stage3;
        end
    end
endmodule