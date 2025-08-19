//SystemVerilog
module sync_low_pass_filter #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);

    // Pipeline stage 1 registers
    reg [DATA_WIDTH-1:0] data_in_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers 
    reg [DATA_WIDTH-1:0] data_in_div2_stage2;
    reg [DATA_WIDTH-1:0] data_in_div4_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [DATA_WIDTH-1:0] prev_sample;
    reg [DATA_WIDTH-1:0] prev_sample_div4_stage3;
    reg valid_stage3;
    
    // Stage 1: Register input
    always @(posedge clk) begin
        if (!rst_n) begin
            data_in_stage1 <= {DATA_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Calculate divisions
    always @(posedge clk) begin
        if (!rst_n) begin
            data_in_div2_stage2 <= {DATA_WIDTH{1'b0}};
            data_in_div4_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_in_div2_stage2 <= {1'b0, data_in_stage1[DATA_WIDTH-1:1]};
            data_in_div4_stage2 <= {2'b00, data_in_stage1[DATA_WIDTH-1:2]};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Calculate final result
    always @(posedge clk) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
            prev_sample <= {DATA_WIDTH{1'b0}};
            prev_sample_div4_stage3 <= {DATA_WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            prev_sample_div4_stage3 <= {2'b00, prev_sample[DATA_WIDTH-1:2]};
            data_out <= data_in_div4_stage2 + data_in_div2_stage2 + prev_sample_div4_stage3;
            prev_sample <= data_out;
            valid_stage3 <= valid_stage2;
            valid_out <= valid_stage3;
        end
    end

endmodule