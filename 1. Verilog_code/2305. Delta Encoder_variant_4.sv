//SystemVerilog
module delta_encoder #(
    parameter WIDTH = 12
)(
    input                   clk_i,
    input                   en_i,
    input                   rst_i,
    input      [WIDTH-1:0]  data_i,
    output reg [WIDTH-1:0]  delta_o,
    output reg              valid_o
);

    // Stage 1 registers
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] prev_sample_stage1;
    reg             valid_stage1;
    
    // Stage 2 registers
    reg [WIDTH-1:0] delta_stage2;
    reg             valid_stage2;
    
    // Pipeline stage 1: Data capture
    always @(posedge clk_i) begin
        if (rst_i) begin
            data_stage1 <= {WIDTH{1'b0}};
        end else if (en_i) begin
            data_stage1 <= data_i;
        end
    end
    
    // Pipeline stage 1: Previous sample storage
    always @(posedge clk_i) begin
        if (rst_i) begin
            prev_sample_stage1 <= {WIDTH{1'b0}};
        end else if (en_i) begin
            prev_sample_stage1 <= data_i;
        end
    end
    
    // Pipeline stage 1: Valid signal generation
    always @(posedge clk_i) begin
        if (rst_i) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= en_i;
        end
    end
    
    // Pipeline stage 2: Delta calculation
    always @(posedge clk_i) begin
        if (rst_i) begin
            delta_stage2 <= {WIDTH{1'b0}};
        end else if (valid_stage1) begin
            delta_stage2 <= data_stage1 - prev_sample_stage1;
        end
    end
    
    // Pipeline stage 2: Valid signal propagation
    always @(posedge clk_i) begin
        if (rst_i) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage: Delta value propagation
    always @(posedge clk_i) begin
        if (rst_i) begin
            delta_o <= {WIDTH{1'b0}};
        end else begin
            delta_o <= delta_stage2;
        end
    end
    
    // Output stage: Valid signal propagation
    always @(posedge clk_i) begin
        if (rst_i) begin
            valid_o <= 1'b0;
        end else begin
            valid_o <= valid_stage2;
        end
    end

endmodule