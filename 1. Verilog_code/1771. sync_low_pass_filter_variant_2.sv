//SystemVerilog
module sync_low_pass_filter #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);

    // Pipeline stage 1 registers
    reg [DATA_WIDTH-1:0] data_in_stage1;
    reg [DATA_WIDTH-1:0] prev_sample_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [DATA_WIDTH-1:0] data_in_stage2;
    reg [DATA_WIDTH-1:0] prev_sample_stage2;
    reg valid_stage2;
    
    // Pipeline stage 1
    always @(posedge clk) begin
        if (!rst_n) begin
            data_in_stage1 <= {DATA_WIDTH{1'b0}};
            prev_sample_stage1 <= {DATA_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            prev_sample_stage1 <= data_out;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk) begin
        if (!rst_n) begin
            data_in_stage2 <= {DATA_WIDTH{1'b0}};
            prev_sample_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            prev_sample_stage2 <= prev_sample_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else if (valid_stage2) begin
            // Simple low-pass: y[n] = 0.75*x[n] + 0.25*y[n-1]
            data_out <= (data_in_stage2 >> 2) + (data_in_stage2 >> 1) + (prev_sample_stage2 >> 2);
        end
    end

endmodule