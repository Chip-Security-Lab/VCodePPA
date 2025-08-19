//SystemVerilog
module crossbar_monitor #(
    parameter DW = 8,
    parameter N = 4
) (
    input clk,
    input rst_n,  // Added reset for proper pipeline initialization
    input [N-1:0][DW-1:0] din,
    output reg [N-1:0][DW-1:0] dout,
    output reg [31:0] traffic_count
);
    // Stage 1: Input sampling and initial processing
    reg [N-1:0][DW-1:0] din_stage1;
    reg [N-1:0] data_valid_stage1;
    reg [31:0] traffic_increment_stage1;
    
    // Stage 2: Connection mapping and traffic counting
    reg [N-1:0][DW-1:0] dout_stage2;
    reg [31:0] traffic_increment_stage2;
    
    integer i;
    
    // Stage 1: Input sampling and data validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < N; i = i + 1) begin
                din_stage1[i] <= {DW{1'b0}};
                data_valid_stage1[i] <= 1'b0;
            end
            traffic_increment_stage1 <= 32'd0;
        end else begin
            // Sample input data
            din_stage1 <= din;
            
            // Detect valid data (non-zero)
            traffic_increment_stage1 <= 32'd0;
            for (i = 0; i < N; i = i + 1) begin
                data_valid_stage1[i] <= |din[i];
                if (|din[i]) begin
                    traffic_increment_stage1 <= traffic_increment_stage1 + 1'b1;
                end
            end
        end
    end
    
    // Stage 2: Connection mapping
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < N; i = i + 1) begin
                dout_stage2[i] <= {DW{1'b0}};
            end
            traffic_increment_stage2 <= 32'd0;
        end else begin
            // Perform crossbar mapping (in reverse order)
            for (i = 0; i < N; i = i + 1) begin
                dout_stage2[i] <= din_stage1[N-1-i];
            end
            
            // Pass traffic increment to next stage
            traffic_increment_stage2 <= traffic_increment_stage1;
        end
    end
    
    // Final stage: Output and counter update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {N{{{DW{1'b0}}}}};
            traffic_count <= 32'd0;
        end else begin
            // Update outputs
            dout <= dout_stage2;
            
            // Update traffic counter
            traffic_count <= traffic_count + traffic_increment_stage2;
        end
    end
endmodule